import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmaco_delivery_partner/core/services/documents_service.dart';

class DocumentsVerificationScreen extends StatefulWidget {
  const DocumentsVerificationScreen({super.key});

  @override
  State<DocumentsVerificationScreen> createState() =>
      _DocumentsVerificationScreenState();
}

class _DocumentsVerificationScreenState
    extends State<DocumentsVerificationScreen> {
  final DocumentsService _documentsService = DocumentsService();
  final TextEditingController _aadhaarController = TextEditingController();
  List<DocumentInfo> _documents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final docs = await _documentsService.getDocumentsStatus();
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('DocumentsVerificationScreen: Error loading documents: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load documents. Please try again.';
        });
      }
    }
  }

  Future<void> _handleUpload(
    String type, {
    Map<String, String>? extraData,
  }) async {
    final ImagePicker picker = ImagePicker();
    final String? action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(Icons.camera_alt, 'Camera', 'camera'),
                  _buildSourceOption(Icons.photo_library, 'Gallery', 'gallery'),
                  _buildSourceOption(Icons.folder_open, 'Files', 'files'),
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
        final source = action == 'camera'
            ? ImageSource.camera
            : ImageSource.gallery;
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (image == null) return;
        file = File(image.path);
      } else if (action == 'files') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: false,
        );
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
        await _documentsService.uploadDocument(
          type,
          file,
          extraData: extraData,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadDocuments();
      } catch (e) {
        debugPrint('DocumentsVerificationScreen: Upload error: $e');
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('DocumentsVerificationScreen: File picking error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: ${e.toString()}')),
      );
    }
  }

  Widget _buildSourceOption(IconData icon, String label, String action) {
    return InkWell(
      onTap: () => Navigator.pop(context, action),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isPdf
                  ? Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 56,
                            color: Colors.red,
                          ),
                          SizedBox(height: 8),
                          Text('PDF selected'),
                        ],
                      ),
                    )
                  : Image.file(
                      file,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              isPdf
                  ? 'Confirm the PDF is correct.'
                  : 'Does the image look clear and readable?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('RETAKE'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int completedCount = _documents
        .where((doc) => doc.status == DocumentStatus.approved)
        .length;
    final int totalCount = _documents.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Documents & Verification',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  _buildProgressHeader(completedCount, totalCount),
                  const SizedBox(height: 32),
                  ..._documents.map((doc) => _buildDocumentCard(doc)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressHeader(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Progress',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed of $total documents approved',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Colors.blue.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentInfo doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getStatusColor(doc.status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getDocIcon(doc.id),
            color: _getStatusColor(doc.status),
            size: 20,
          ),
        ),
        title: Text(
          doc.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(children: [_buildStatusBadge(doc.status)]),
        ),
        trailing: doc.status == DocumentStatus.approved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.keyboard_arrow_down),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _getHelperText(doc.id),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (doc.id == 'gov_id') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _aadhaarController,
                    decoration: InputDecoration(
                      labelText: 'Aadhaar Number',
                      hintText: 'Enter 12-digit Aadhaar',
                      prefixIcon: const Icon(Icons.pin),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                  ),
                ],
                if (doc.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: ${doc.rejectionReason}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (doc.status != DocumentStatus.approved)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (doc.id == 'gov_id' &&
                          _aadhaarController.text.length != 12) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid 12-digit Aadhaar number',
                            ),
                          ),
                        );
                        return;
                      }
                      _handleUpload(
                        doc.id,
                        extraData: doc.id == 'gov_id'
                            ? {'aadhaar_number': _aadhaarController.text}
                            : null,
                      );
                    },
                    icon: Icon(
                      doc.status == DocumentStatus.notUploaded
                          ? Icons.upload
                          : Icons.refresh,
                    ),
                    label: Text(
                      doc.status == DocumentStatus.notUploaded
                          ? 'UPLOAD NOW'
                          : 'RE-UPLOAD DOCUMENT',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('VIEW DOCUMENT'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getDocIcon(String id) {
    switch (id) {
      case 'gov_id':
        return Icons.badge_outlined;
      case 'driving_license':
        return Icons.directions_car_outlined;
      case 'bank_details':
        return Icons.account_balance_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _getHelperText(String id) {
    switch (id) {
      case 'gov_id':
        return 'We need your Government ID (Aadhar/PAN) to comply with healthcare regulations.';
      case 'driving_license':
        return 'Mandatory for all partners delivering via bike or scooter.';
      case 'bank_details':
        return 'Accurate bank or UPI details ensure instant commission payouts.';
      default:
        return 'Required for verification.';
    }
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return Colors.green;
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.notUploaded:
        return Colors.grey;
    }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return 'APPROVED';
      case DocumentStatus.pending:
        return 'PENDING VERIFICATION';
      case DocumentStatus.rejected:
        return 'REJECTED';
      case DocumentStatus.notUploaded:
        return 'NOT UPLOADED';
    }
  }
}
