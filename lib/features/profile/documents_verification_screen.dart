import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmaco_delivery_partner/core/services/documents_service.dart';
import 'package:pharmaco_delivery_partner/theme/design_tokens.dart';

class DocumentsVerificationScreen extends StatefulWidget {
  const DocumentsVerificationScreen({super.key});

  @override
  State<DocumentsVerificationScreen> createState() => _DocumentsVerificationScreenState();
}

class _DocumentsVerificationScreenState extends State<DocumentsVerificationScreen> {
  final DocumentsService _documentsService = DocumentsService();
  final TextEditingController _aadhaarController = TextEditingController();
  List<DocumentInfo> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() { super.initState(); _loadDocuments(); }

  @override
  void dispose() { _aadhaarController.dispose(); super.dispose(); }

  Future<void> _loadDocuments() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final docs = await _documentsService.getDocumentsStatus();
      if (mounted) setState(() { _documents = docs; _isLoading = false; });
    } catch (e) {
      debugPrint('DocumentsVerificationScreen: Error loading documents: $e');
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Failed to load documents. Please try again.'; });
    }
  }

  Future<void> _handleUpload(String type, {Map<String, String>? extraData}) async {
    final ImagePicker picker = ImagePicker();
    final String? action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(PharmacoTokens.radiusCard))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PharmacoTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Source', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
              const SizedBox(height: PharmacoTokens.space20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(Icons.camera_alt_rounded, 'Camera', 'camera'),
                  _buildSourceOption(Icons.photo_library_rounded, 'Gallery', 'gallery'),
                  _buildSourceOption(Icons.folder_open_rounded, 'Files', 'files'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null) return;

    try {
      File? file;
      if (action == 'camera' || action == 'gallery') {
        final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
        final XFile? image = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
        if (image == null) return;
        file = File(image.path);
      } else if (action == 'files') {
        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], withData: false);
        if (result == null || result.files.isEmpty) return;
        final pickedPath = result.files.single.path;
        if (pickedPath == null) return;
        file = File(pickedPath);
      }
      if (file == null) return;
      if (!mounted) return;
      final confirmed = await _showPreviewDialog(file);
      if (confirmed != true) return;

      setState(() => _isLoading = true);
      try {
        await _documentsService.uploadDocument(type, file, extraData: extraData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: PharmacoTokens.success));
        await _loadDocuments();
      } catch (e) {
        debugPrint('DocumentsVerificationScreen: Upload error: $e');
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${e.toString()}'), backgroundColor: PharmacoTokens.error));
      }
    } catch (e) {
      debugPrint('DocumentsVerificationScreen: File picking error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting file: ${e.toString()}')));
    }
  }

  Widget _buildSourceOption(IconData icon, String label, String action) {
    return InkWell(
      onTap: () => Navigator.pop(context, action),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(PharmacoTokens.space16), decoration: const BoxDecoration(color: PharmacoTokens.primarySurface, shape: BoxShape.circle), child: Icon(icon, color: PharmacoTokens.primaryBase, size: 28)),
          const SizedBox(height: PharmacoTokens.space8),
          Text(label, style: const TextStyle(fontWeight: PharmacoTokens.weightMedium)),
        ],
      ),
    );
  }

  Future<bool?> _showPreviewDialog(File file) {
    final ext = file.path.toLowerCase();
    final isPdf = ext.endsWith('.pdf');
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: PharmacoTokens.borderRadiusCard),
        title: const Text('Confirm Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: PharmacoTokens.borderRadiusMedium,
              child: isPdf
                  ? Container(height: 200, width: double.infinity, color: PharmacoTokens.neutral100, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.picture_as_pdf_rounded, size: 56, color: PharmacoTokens.error), SizedBox(height: 8), Text('PDF selected')]))
                  : Image.file(file, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: PharmacoTokens.space16),
            Text(isPdf ? 'Confirm the PDF is correct.' : 'Does the image look clear and readable?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('RETAKE')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('CONFIRM')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int completedCount = _documents.where((doc) => doc.status == DocumentStatus.approved).length;
    final int totalCount = _documents.length;
    final bool allApproved = _documents.isNotEmpty && _documents.every((doc) => doc.status == DocumentStatus.approved);

    return Scaffold(
      backgroundColor: PharmacoTokens.neutral50,
      appBar: AppBar(title: const Text('Documents & Verification')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PharmacoTokens.primaryBase))
          : RefreshIndicator(
              color: PharmacoTokens.primaryBase,
              onRefresh: _loadDocuments,
              child: ListView(
                padding: const EdgeInsets.all(PharmacoTokens.space20),
                children: [
                  _buildProgressHeader(completedCount, totalCount, theme),
                  const SizedBox(height: PharmacoTokens.space32),
                  ..._documents.map((doc) => _buildDocumentCard(doc, theme)),
                  const SizedBox(height: PharmacoTokens.space20),
                ],
              ),
            ),
      floatingActionButton: allApproved
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              backgroundColor: PharmacoTokens.success,
              foregroundColor: PharmacoTokens.white,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('DONE'),
            )
          : null,
    );
  }

  Widget _buildProgressHeader(int completed, int total, ThemeData theme) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(PharmacoTokens.space24),
      decoration: BoxDecoration(color: PharmacoTokens.primarySurface, borderRadius: PharmacoTokens.borderRadiusCard),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Verification Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.primaryDark)),
                const SizedBox(height: 4),
                Text('$completed of $total documents approved', style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.primaryBase)),
              ]),
              Text('${(progress * 100).toInt()}%', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: PharmacoTokens.weightBold, color: PharmacoTokens.primaryDark)),
            ],
          ),
          const SizedBox(height: PharmacoTokens.space20),
          LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4), backgroundColor: PharmacoTokens.primaryBase.withValues(alpha: 0.15), valueColor: const AlwaysStoppedAnimation<Color>(PharmacoTokens.primaryBase)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentInfo doc, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: PharmacoTokens.space16),
      decoration: BoxDecoration(color: PharmacoTokens.white, borderRadius: PharmacoTokens.borderRadiusCard, boxShadow: PharmacoTokens.shadowZ1()),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: PharmacoTokens.space20, vertical: PharmacoTokens.space8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _getStatusColor(doc.status).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_getDocIcon(doc.id), color: _getStatusColor(doc.status), size: 20),
        ),
        title: Text(doc.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: PharmacoTokens.weightBold)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Row(children: [_buildStatusBadge(doc.status)])),
        trailing: doc.status == DocumentStatus.approved ? const Icon(Icons.check_circle_rounded, color: PharmacoTokens.success) : const Icon(Icons.keyboard_arrow_down_rounded),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(PharmacoTokens.space20, 0, PharmacoTokens.space20, PharmacoTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_getHelperText(doc.id), style: theme.textTheme.bodySmall?.copyWith(color: PharmacoTokens.neutral500, height: 1.4)),
                if (doc.id == 'gov_id') ...[
                  const SizedBox(height: PharmacoTokens.space16),
                  TextFormField(controller: _aadhaarController, decoration: const InputDecoration(labelText: 'Aadhaar Number', hintText: 'Enter 12-digit Aadhaar', prefixIcon: Icon(Icons.pin_rounded)), keyboardType: TextInputType.number, maxLength: 12),
                ],
                if (doc.rejectionReason != null) ...[
                  const SizedBox(height: PharmacoTokens.space12),
                  Container(
                    padding: const EdgeInsets.all(PharmacoTokens.space12),
                    decoration: BoxDecoration(color: PharmacoTokens.error.withValues(alpha: 0.08), borderRadius: PharmacoTokens.borderRadiusMedium),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: PharmacoTokens.error, size: 18),
                      const SizedBox(width: PharmacoTokens.space8),
                      Expanded(child: Text('Reason: ${doc.rejectionReason}', style: const TextStyle(color: PharmacoTokens.error, fontSize: 12))),
                    ]),
                  ),
                ],
                const SizedBox(height: PharmacoTokens.space20),
                if (doc.status != DocumentStatus.approved)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (doc.id == 'gov_id' && _aadhaarController.text.length != 12) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 12-digit Aadhaar number')));
                        return;
                      }
                      _handleUpload(doc.id, extraData: doc.id == 'gov_id' ? {'aadhaar_number': _aadhaarController.text} : null);
                    },
                    icon: Icon(doc.status == DocumentStatus.notUploaded ? Icons.upload_rounded : Icons.refresh_rounded),
                    label: Text(doc.status == DocumentStatus.notUploaded ? 'UPLOAD NOW' : 'RE-UPLOAD DOCUMENT'),
                  )
                else
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('VIEW DOCUMENT')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DocumentStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: PharmacoTokens.borderRadiusFull, border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Text(_getStatusText(status), style: TextStyle(color: color, fontSize: 10, fontWeight: PharmacoTokens.weightBold)),
    );
  }

  IconData _getDocIcon(String id) {
    switch (id) { case 'gov_id': return Icons.badge_outlined; case 'driving_license': return Icons.directions_car_outlined; case 'bank_details': return Icons.account_balance_outlined; default: return Icons.description_outlined; }
  }

  String _getHelperText(String id) {
    switch (id) { case 'gov_id': return 'We need your Government ID (Aadhar/PAN) to comply with healthcare regulations.'; case 'driving_license': return 'Mandatory for all partners delivering via bike or scooter.'; case 'bank_details': return 'Accurate bank or UPI details ensure instant commission payouts.'; default: return 'Required for verification.'; }
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) { case DocumentStatus.approved: return PharmacoTokens.success; case DocumentStatus.pending: return PharmacoTokens.warning; case DocumentStatus.rejected: return PharmacoTokens.error; case DocumentStatus.notUploaded: return PharmacoTokens.neutral400; }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) { case DocumentStatus.approved: return 'APPROVED'; case DocumentStatus.pending: return 'PENDING VERIFICATION'; case DocumentStatus.rejected: return 'REJECTED'; case DocumentStatus.notUploaded: return 'NOT UPLOADED'; }
  }
}
