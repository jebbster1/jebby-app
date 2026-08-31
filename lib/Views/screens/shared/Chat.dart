import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/screens/home/Messages.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/view_model/apiServices.dart';
import 'package:provider/provider.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/user_model.dart';
import '../../../view_model/user_view_model.dart';
import '../../../model/getAllMessagesModel.dart' as msg_model;
import '../../../model/getChatHistoryModel.dart' as datamodel;
import '../../../model/product_chat_context.dart';
import '../../../utils/api_datetime.dart';

class _CachedThreadInquiry {
  const _CachedThreadInquiry({
    required this.content,
    required this.recipientId,
  });

  final String content;
  final String recipientId;
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.showBackButton = false});

  /// When true (e.g. opened from provider drawer), shows a leading back affordance.
  final bool showBackButton;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Future<void> getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String sourceId = "";
  String? fullname;
  String? email;
  String? role;

  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          sourceId = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
          _applyDefaultTab();
          get_chat_history();
          seenNotification();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  void seenNotification() {
    ApiRepository.shared.seenNotification(sourceId);
  }

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  final Map<String, _CachedThreadInquiry> _threadInquiryCache = {};
  bool _resolvingInquiries = false;

  void get_chat_history() {
    ApiRepository.shared.chatsHistory(
      sourceId.toString(),
      (payload) {
        if (!mounted) return;
        if (payload.data == null || payload.data!.isEmpty) {
          setState(() {
            isEmpty = true;
            isLoading = false;
            isError = false;
          });
        } else {
          setState(() {
            isEmpty = false;
            isLoading = false;
            isError = false;
          });
          _resolveThreadInquiries();
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() {
            isEmpty = false;
            isLoading = false;
            isError = true;
          });
        }
      },
    );
  }

  Timer? _pollTimer;

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => get_chat_history(),
    );
  }

  final TextEditingController _searchController = TextEditingController();
  String searchText = "";

  List<datamodel.Data> _visibleChats() {
    final raw = ApiRepository.shared.getChatsHistoryModelList?.data;
    if (raw == null) return [];
    final rev = raw.reversed.toList();
    if (searchText.isEmpty) return rev;
    final q = searchText.toLowerCase();
    return rev
        .where((e) => (e.name ?? '').toString().toLowerCase().contains(q))
        .toList();
  }

  String? _inquiryContentFor(datamodel.Data e) {
    final peerId = e.id.toString();
    final cached = _threadInquiryCache[peerId];
    if (cached != null) return cached.content;

    final inquiry = (e.lastInquiryMessage ?? '').trim();
    if (inquiry.isNotEmpty) return inquiry;
    return e.lastMessage;
  }

  bool _isProviderTabConversation(datamodel.Data e) {
    if (sourceId.isEmpty) return false;
    final inquiryContent = _inquiryContentFor(e);
    return ProductChatContext.isProviderTabThread(
      inquiryContent: inquiryContent,
      currentUserId: sourceId,
    );
  }

  Future<void> _resolveThreadInquiries() async {
    if (sourceId.isEmpty || _resolvingInquiries) return;
    final raw = ApiRepository.shared.getChatsHistoryModelList?.data;
    if (raw == null || raw.isEmpty) return;

    _resolvingInquiries = true;
    for (final e in raw) {
      final peerId = e.id.toString();
      if (_threadInquiryCache.containsKey(peerId)) continue;
      if ((e.lastInquiryMessage ?? '').trim().isNotEmpty) continue;
      if (ProductChatContext.tryParsePayload(e.lastMessage) != null) continue;
      await _fetchThreadInquiry(peerId);
    }
    _resolvingInquiries = false;
    if (mounted) setState(() {});
  }

  Future<void> _fetchThreadInquiry(String peerId) async {
    final completer = Completer<void>();
    ApiRepository.shared.getMessagesApi(
      sourceId,
      peerId,
      (res) {
        final meta = _extractLatestInquiry(res.data);
        if (meta != null) {
          _threadInquiryCache[peerId] = meta;
        }
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  _CachedThreadInquiry? _extractLatestInquiry(List<msg_model.Data>? messages) {
    if (messages == null || messages.isEmpty) return null;

    final sorted = List<msg_model.Data>.from(messages);
    sorted.sort((a, b) {
      final ta = parseApiDateTime(a.createdAt) ?? DateTime(1970);
      final tb = parseApiDateTime(b.createdAt) ?? DateTime(1970);
      return ta.compareTo(tb);
    });

    for (var i = sorted.length - 1; i >= 0; i--) {
      final m = sorted[i];
      final content = (m.content ?? '').toString();
      final ctx = ProductChatContext.tryParsePayload(content);
      if (ctx != null) {
        final recipientId = m.recipientId?.toString() ?? ctx.recipientId;
        return _CachedThreadInquiry(
          content: content,
          recipientId: recipientId,
        );
      }

      final productId = m.productId;
      final messageRecipientId = m.recipientId;
      if (productId != null && productId > 0 && messageRecipientId != null) {
        final rid = messageRecipientId.toString();
        // Product inquiries are sent to the vendor; listing owner is recipient (or self when vendor).
        final vendorId = rid == sourceId ? sourceId : rid;
        return _CachedThreadInquiry(
          content: ProductChatContext.syntheticPayload(
            productId: productId,
            vendorUserId: vendorId,
            recipientId: rid,
          ),
          recipientId: rid,
        );
      }
    }
    return null;
  }

  bool _isRenterTabConversation(datamodel.Data e) => !_isProviderTabConversation(e);

  List<datamodel.Data> _chatsForProviderTab(List<datamodel.Data> items) {
    return items.where(_isProviderTabConversation).toList();
  }

  List<datamodel.Data> _chatsForRenterTab(List<datamodel.Data> items) {
    return items.where(_isRenterTabConversation).toList();
  }

  void _initTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _applyDefaultTab() {
    final tabs = _tabController;
    if (!mounted || tabs == null || role == null) return;
    final index = role == '1' ? 1 : 0;
    if (tabs.index != index) {
      tabs.index = index;
    }
  }

  @override
  void initState() {
    super.initState();
    _initTabController();
    _startPoll();
    getData();
    profileData(context);
  }

  @override
  void activate() {
    super.activate();
    if (_tabController == null) {
      _initTabController();
      _applyDefaultTab();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _tabController = null;
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabController;
    if (tabs == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          widget.showBackButton
              ? const Color(0xFFF3F3F5)
              : Colors.grey.shade100,
      appBar:
          widget.showBackButton
              ? AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                foregroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Get.back(),
                  style: IconButton.styleFrom(foregroundColor: Colors.black),
                ),
              )
              : null,
      body: SafeArea(
        top: !widget.showBackButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.showBackButton ? 20 : 18,
                widget.showBackButton ? 0 : 10,
                12,
                0,
              ),
              child: Text(
                'Chat',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight:
                      widget.showBackButton ? FontWeight.w800 : FontWeight.w700,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: _SearchPill(
                controller: _searchController,
                onChanged: (v) {
                  setState(() => searchText = v.toLowerCase());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: TabBar(
                controller: tabs,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 2.5,
                labelColor: Colors.black,
                unselectedLabelColor: const Color(0xFF9E9E9E),
                labelStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Renter'),
                  Tab(text: 'Provider'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildBody(tabs)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TabController tabs) {
    if (isError) {
      return Center(
        child: Text(
          'Something went wrong while loading chats.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.black54),
        ),
      );
    }
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    final items = _visibleChats();
    if (isEmpty || items.isEmpty) {
      return Center(
        child: Text(
          'No messages',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      );
    }

    return TabBarView(
      controller: tabs,
      children: [
        _buildChatList(_chatsForRenterTab(items), emptyLabel: 'No renter chats'),
        _buildChatList(_chatsForProviderTab(items), emptyLabel: 'No provider chats'),
      ],
    );
  }

  Widget _buildChatList(List<datamodel.Data> items, {required String emptyLabel}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 1, 15, 24),
      children: _chatTiles(items),
    );
  }

  List<Widget> _chatTiles(List<datamodel.Data> items) {
    return items.map((element) {
      final name = element.name;
      final image = element.image.toString();
      final targetId = element.id.toString();
      final count = element.count ?? 0;
      final lastMessage = (element.lastMessage ?? '').toString();
      final displayName =
          (name == null || name.toString().trim().isEmpty)
              ? 'Vendor'
              : name.toString();

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ChatListTile(
          name: displayName,
          imageUrl: image.isEmpty ? null : AppUrl.baseUrlM + image,
          lastMessage: lastMessage,
          unreadCount: count,
          onTap: () {
            _pollTimer?.cancel();
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => Chat(targetId)))
                .then((_) {
                  if (!mounted) return;
                  get_chat_history();
                  _startPoll();
                });
          },
        ),
      );
    }).toList();
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade500, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.name,
    required this.imageUrl,
    required this.lastMessage,
    required this.unreadCount,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final String lastMessage;
  final int unreadCount;
  final VoidCallback onTap;

  String get _preview {
    final text = ProductChatContext.formatLastMessagePreview(lastMessage);
    if (text.length <= 80) return text;
    return '${text.substring(0, 77)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(imageUrl: imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6B70),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl});

  final String? imageUrl;

  static const Color _fill = Color(0xFFFFF4E8);

  @override
  Widget build(BuildContext context) {
    const size = 54.0;
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: _fill,
        child: Icon(
          Icons.person_rounded,
          color: AppColors.primaryColor.withValues(alpha: 0.85),
          size: 30,
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => ColoredBox(
                color: _fill,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryColor.withValues(alpha: 0.85),
                  size: 30,
                ),
              ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return ColoredBox(
              color: _fill,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
