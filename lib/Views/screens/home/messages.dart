import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/getAllMessagesModel.dart' as msg_model;
import '../../../model/product_chat_context.dart';
import '../../../model/user_model.dart';
import '../../../res/app_url.dart';
import '../../../res/color.dart';
import '../../../utils/api_datetime.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';
import 'ProductDetails.dart';

class Chat extends StatefulWidget {
  const Chat(this.targetID, {super.key, this.productContext});

  final dynamic targetID;
  final ProductChatContext? productContext;

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _sendMessageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer;

  String? token;
  String sourceId = "";
  String? fullname;
  String? email;
  String? phoneNumber;
  String? role;

  String _peerDisplayName = '';
  String _targetImage = '';

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  /// Detects new/changed thread so we only auto-scroll when messages update.
  String? _lastMessagesFingerprint;

  bool _productContextSent = false;

  Future<void> getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  void profileData(BuildContext context) {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          sourceId = value.id.toString();
          fullname = value.name.toString();
          phoneNumber = value.phoneNumber.toString();
          email = value.email.toString();
          role = value.role.toString();
          if (mounted) setState(() {});
          getUserData();
          getMessageApi();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  void getMessageApi() {
    if (sourceId.isEmpty || widget.targetID.toString().isEmpty) return;
    ApiRepository.shared.getMessagesApi(
      sourceId.toString(),
      widget.targetID.toString(),
      (res) {
        if (!mounted) return;
        final newFp = _fingerprintMessages(res.data);
        final changed = _lastMessagesFingerprint != newFp;

        if (res.data == null || res.data!.isEmpty) {
          setState(() {
            isLoading = false;
            isEmpty = true;
            isError = false;
          });
          if (changed) {
            _lastMessagesFingerprint = newFp;
            _scheduleScrollToBottom();
          }
          _maybeSendProductContext(const []);
        } else {
          setState(() {
            isLoading = false;
            isError = false;
            isEmpty = false;
          });
          if (changed) {
            _lastMessagesFingerprint = newFp;
            _scheduleScrollToBottom();
          }
          _maybeSendProductContext(res.data!);
        }
      },
      (error) {
        if (!mounted) return;
        if (error != null) {
          setState(() {
            isLoading = false;
            isError = true;
            isEmpty = false;
          });
        }
      },
    );
  }

  void sendMessage(String msg, {String? productId}) {
    if (msg.trim().isEmpty) return;
    final effectiveProductId = productId ?? widget.productContext?.productId;
    ApiRepository.shared.postMessage(
      msg.trim(),
      sourceId.toString(),
      widget.targetID.toString(),
      productId: effectiveProductId,
    );
  }

  void _maybeSendProductContext(List<msg_model.Data> existing) {
    final ctx = widget.productContext;
    if (ctx == null || _productContextSent || sourceId.isEmpty) return;
    if (ProductChatContext.threadHasProduct(
      contents: existing.map((m) => m.content),
      productIds: existing.map((m) => m.productId),
      productId: ctx.productId,
    )) {
      _productContextSent = true;
      return;
    }
    _productContextSent = true;
    sendMessage(ctx.toPayload(), productId: ctx.productId);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) getMessageApi();
    });
  }

  void getUserData() {
    ApiRepository.shared.userCredential(
      (List) {
        if (!mounted) return;
        if (List.data == null || List.data!.isEmpty) {
          setState(() {});
        } else {
          setState(() {});
        }
      },
      (error) {
        if (error != null && mounted) setState(() {});
      },
      sourceId.toString(),
    );
  }

  void getTargetData() {
    ApiRepository.shared.userCredential(
      (List) {
        if (!mounted) return;
        if (List.data == null || List.data!.isEmpty) {
          setState(() {
            _peerDisplayName = 'Chat';
            _targetImage = '';
          });
        } else {
          final row = List.data![0];
          setState(() {
            _peerDisplayName =
                (row.name ?? '').toString().trim().isEmpty
                    ? 'Chat'
                    : (row.name ?? '').toString().trim();
            _targetImage = (row.profileImage ?? '').toString();
          });
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() => _peerDisplayName = 'Chat');
        }
      },
      widget.targetID.toString(),
    );
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && sourceId.isNotEmpty) getMessageApi();
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
    profileData(context);
    getTargetData();
    _startPoll();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sendMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static const Color _pageBg = Color(0xFFF5F5F5);

  String _firstName(String? full) {
    if (full == null || full.trim().isEmpty) return 'You';
    return full.trim().split(RegExp(r'\s+')).first;
  }

  String _peerFirstName() => _firstName(_peerDisplayName);

  String _avatarUrl(String rel) {
    final t = rel.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('http')) return t;
    return '${AppUrl.baseUrlM}$t';
  }

  List<msg_model.Data> _messagesChronological() {
    final raw = ApiRepository.shared.getAllMessagesModelList?.data;
    return _sortMessagesChronological(raw);
  }

  List<msg_model.Data> _sortMessagesChronological(List<msg_model.Data>? raw) {
    if (raw == null || raw.isEmpty) return [];
    final list = List<msg_model.Data>.from(raw);
    list.sort((a, b) {
      final ta = parseApiDateTime(a.createdAt) ?? DateTime(1970);
      final tb = parseApiDateTime(b.createdAt) ?? DateTime(1970);
      return ta.compareTo(tb);
    });
    return list;
  }

  String _fingerprintMessages(List<msg_model.Data>? data) {
    final sorted = _sortMessagesChronological(data);
    if (sorted.isEmpty) return 'empty';
    final last = sorted.last;
    return '${sorted.length}_${last.id}_${last.createdAt}_${last.content}';
  }

  /// With [reverse: true], offset 0 is the visual bottom (newest).
  void _scrollToBottom() {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgs = _messagesChronological();

    return Scaffold(
      backgroundColor: _pageBg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(foregroundColor: Colors.black),
        ),
        title: Row(
          children: [
            if (!isLoading) ...[
              _HeaderAvatar(imageUrl: _avatarUrl(_targetImage)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                _peerDisplayName.isEmpty ? 'Chat' : _peerDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: Text(
                        'Loading…',
                        style: GoogleFonts.inter(color: Colors.black54),
                      ),
                    )
                    : isError
                    ? Center(
                      child: Text(
                        'Could not load messages',
                        style: GoogleFonts.inter(color: Colors.black54),
                      ),
                    )
                    : isEmpty || msgs.isEmpty
                    ? _EmptyThreadBody(productContext: widget.productContext)
                    : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final msgIndex = msgs.length - 1 - index;
                        final m = msgs[msgIndex];
                        final isMe =
                            m.senderId.toString() == sourceId.toString();
                        final showSenderHeader =
                            msgIndex == 0 ||
                            msgs[msgIndex - 1].senderId != m.senderId;
                        final sameSenderAsOlder =
                            msgIndex > 0 &&
                            msgs[msgIndex - 1].senderId == m.senderId;
                        final topPad = sameSenderAsOlder ? 4.0 : 12.0;
                        final content = (m.content ?? '').toString();
                        final productCtx =
                            ProductChatContext.tryParsePayload(content);

                        return Padding(
                          padding: EdgeInsets.only(top: topPad),
                          child:
                              productCtx != null
                                  ? _ProductInquiryCard(
                                    product: productCtx,
                                    createdAt: m.createdAt,
                                    isMe: isMe,
                                    showSenderHeader: showSenderHeader,
                                    senderLabel:
                                        isMe
                                            ? _firstName(fullname)
                                            : _peerFirstName(),
                                  )
                                  : _MessageRow(
                                    content: content,
                                    createdAt: m.createdAt,
                                    isMe: isMe,
                                    showSenderHeader: showSenderHeader,
                                    senderLabel:
                                        isMe
                                            ? _firstName(fullname)
                                            : _peerFirstName(),
                                  ),
                        );
                      },
                    ),
          ),
          _Composer(
            controller: _sendMessageController,
            onSend: () {
              final text = _sendMessageController.text;
              if (text.trim().isEmpty) return;
              sendMessage(text);
              _sendMessageController.clear();
              _scheduleScrollToBottom();
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyThreadBody extends StatelessWidget {
  const _EmptyThreadBody({this.productContext});

  final ProductChatContext? productContext;

  @override
  Widget build(BuildContext context) {
    if (productContext != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        children: [
          _ProductInquiryCard(
            product: productContext!,
            isMe: true,
            showSenderHeader: true,
            senderLabel: 'You',
          ),
        ],
      );
    }
    return Center(
      child: Text(
        'Start your chat',
        style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
      ),
    );
  }
}

class _ProductInquiryCard extends StatelessWidget {
  const _ProductInquiryCard({
    required this.product,
    this.createdAt,
    required this.isMe,
    required this.showSenderHeader,
    required this.senderLabel,
  });

  final ProductChatContext product;
  final String? createdAt;
  final bool isMe;
  final bool showSenderHeader;
  final String senderLabel;

  static const Color _accent = Color(0xFFF6AE02);

  String _resolveImageUrl() {
    final rel = product.image.trim();
    if (rel.isEmpty) return '';
    if (rel.startsWith('http')) return rel;
    return '${AppUrl.baseUrlM}$rel';
  }

  void _openProduct() {
    Get.to(
      () => ProductDetailScreen(
        product.productId,
        product.name,
        product.price,
        '0',
        product.image,
        '',
        product.vendorUserId,
        '',
        0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.88;
    final timeStr = formatApiTime(createdAt);
    final imageUrl = _resolveImageUrl();

    final card = Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openProduct,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8E8)),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child:
                      imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          )
                          : ColoredBox(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade400,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product inquiry',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B6B70),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view listing',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderHeader)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                senderLabel,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B6B70),
                ),
              ),
            ),
          card,
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.imageUrl});

  final String imageUrl;

  static const Color _placeholderFill = Color(0xFFFFF4E8);

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl.isNotEmpty;
    final accent = AppColors.primaryColor.withValues(alpha: 0.85);
    return CircleAvatar(
      radius: 18,
      backgroundColor: _placeholderFill,
      backgroundImage: hasUrl ? CachedNetworkImageProvider(imageUrl) : null,
      onBackgroundImageError: hasUrl ? (_, __) {} : null,
      child: hasUrl ? null : Icon(Icons.person, color: accent, size: 22),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.content,
    required this.createdAt,
    required this.isMe,
    required this.showSenderHeader,
    required this.senderLabel,
  });

  final String content;
  final String? createdAt;
  final bool isMe;
  final bool showSenderHeader;
  final String senderLabel;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.78;
    final timeStr = formatApiTime(createdAt);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSenderHeader) ...[
            Text(
              senderLabel,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isMe ? Colors.white70 : const Color(0xFF6B6B70),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: isMe ? Colors.white : Colors.black,
            ),
          ),
          if (timeStr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: isMe ? Colors.white54 : const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    // Do not add viewInsets.bottom here: Scaffold already insets the body
    // when resizeToAvoidBottomInset is true; duplicating it leaves a gap
    // above the keyboard.
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    cursorColor: AppColors.primaryColor,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Message',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.fromLTRB(
                        14,
                        10,
                        8,
                        10,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                InkWell(
                  onTap: onSend,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Image.asset(
                      'assets/images/chatsendicon.png',
                      height: 40,
                      width: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MessageModel {
  String? Message;
  String? type;

  MessageModel({this.Message, this.type});
}

class StreamSocket {
  final _socketResponse = StreamController<String>();

  void Function(String) get addResponse => _socketResponse.sink.add;

  Stream<String> get getResponse => _socketResponse.stream;

  void dispose() {
    _socketResponse.close();
  }
}
