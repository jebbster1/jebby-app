import 'package:flutter/material.dart';

import '../../../view_model/apiServices.dart';
import '../../widgets/cms_page_shell.dart';

class CmsPolicyScreen extends StatefulWidget {
  const CmsPolicyScreen({
    super.key,
    required this.slug,
    required this.title,
    this.emptyMessage = 'Unable to load content. Please try again later.',
  });

  final String slug;
  final String title;
  final String emptyMessage;

  @override
  State<CmsPolicyScreen> createState() => _CmsPolicyScreenState();
}

class _CmsPolicyScreenState extends State<CmsPolicyScreen> {
  bool isLoading = true;
  bool isError = false;
  bool emptyData = false;

  void _loadPage() {
    ApiRepository.shared.fetchCmsPage(
      widget.slug,
      (model) {
        if (!mounted) return;
        if (model.status == 0 || model.data == null || model.data!.isEmpty) {
          setState(() {
            isLoading = false;
            emptyData = true;
            isError = false;
          });
        } else {
          setState(() {
            isLoading = false;
            emptyData = false;
            isError = false;
          });
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() {
            isLoading = false;
            isError = true;
            emptyData = false;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  String? _htmlBody() {
    final page = ApiRepository.shared.cmsPageForSlug(widget.slug);
    final list = page?.data;
    if (list == null || list.isEmpty) return null;
    return list.first.description?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return CmsPageShell(
      title: widget.title,
      body: CmsPageShell.htmlPolicyScroll(
        isLoading: isLoading,
        isError: isError,
        emptyData: emptyData,
        html: _htmlBody(),
        emptyMessage: widget.emptyMessage,
      ),
    );
  }
}
