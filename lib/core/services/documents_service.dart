import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

enum DocumentStatus { notUploaded, pending, approved, rejected }

class DocumentInfo {
  final String id;
  final String name;
  final DocumentStatus status;
  final String? url;
  final String? rejectionReason;
  final bool isMandatory;

  DocumentInfo({
    required this.id,
    required this.name,
    required this.status,
    this.url,
    this.rejectionReason,
    this.isMandatory = true,
  });
}

class DocumentsService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'partner-documents';

  Future<List<DocumentInfo>> getDocumentsStatus() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    debugPrint('DocumentsService: Fetching documents for $userId');

    try {
      // Fetch from both sources to ensure synchronization
      final docResponse = await _client
          .from('partner_documents')
          .select()
          .eq('partner_id', userId);

      final profileResponse = await _client
          .from('profiles')
          .select(
            'aadhaar_image_url, aadhaar_status, driving_license_url, driving_license_status',
          )
          .eq('id', userId)
          .single();

      final docs = List<Map<String, dynamic>>.from(docResponse);

      // Map of required documents
      final requiredDocs = {
        'gov_id': 'Government ID',
        'driving_license': 'Driving License',
        'bank_details': 'Bank / UPI Details',
      };

      return requiredDocs.entries.map((entry) {
        // Find in partner_documents
        var docData = docs.firstWhere(
          (d) => d['document_type'] == entry.key,
          orElse: () => {},
        );

        // Fallback to profiles table for specific fields if partner_documents is empty
        if (docData.isEmpty) {
          if (entry.key == 'gov_id' &&
              profileResponse['aadhaar_image_url'] != null) {
            docData = {
              'document_url': profileResponse['aadhaar_image_url'],
              'status': profileResponse['aadhaar_status'],
            };
          } else if (entry.key == 'driving_license' &&
              profileResponse['driving_license_url'] != null) {
            docData = {
              'document_url': profileResponse['driving_license_url'],
              'status': profileResponse['driving_license_status'],
            };
          }
        }

        return DocumentInfo(
          id: entry.key,
          name: entry.value,
          status: _mapStatus(docData['status']),
          url: docData['document_url'],
          rejectionReason: docData['rejection_reason'],
        );
      }).toList();
    } catch (e) {
      debugPrint('DocumentsService: Error in getDocumentsStatus: $e');
      rethrow;
    }
  }

  Future<void> uploadDocument(
    String type,
    File file, {
    Map<String, String>? extraData,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final fileExt = path.extension(file.path).toLowerCase();
    const allowedExtensions = <String>{'.jpg', '.jpeg', '.png', '.pdf'};
    if (!allowedExtensions.contains(fileExt)) {
      throw Exception(
        'Unsupported file format. Please upload JPG, PNG, or PDF.',
      );
    }

    final contentType = switch (fileExt) {
      '.pdf' => 'application/pdf',
      '.png' => 'image/png',
      '.jpg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
    final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
    final filePath = '$userId/$fileName';

    try {
      debugPrint('DocumentsService: Uploading $type for user $userId');

      // 1. Upload to Storage
      await _client.storage
          .from(_bucketName)
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );

      // 2. Get Public URL
      final url = _client.storage.from(_bucketName).getPublicUrl(filePath);

      debugPrint('DocumentsService: Upload successful. URL: $url');

      // 3. Update partner_documents table (Scalable approach)
      await _client.from('partner_documents').upsert({
        'partner_id': userId,
        'document_type': type,
        'document_url': url,
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'partner_id, document_type');

      // 4. Also update profiles table for requested fields
      final profileUpdates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (type == 'gov_id') {
        profileUpdates['aadhaar_image_url'] = url;
        profileUpdates['aadhaar_status'] = 'pending';
        if (extraData != null && extraData.containsKey('aadhaar_number')) {
          profileUpdates['aadhaar_number'] = extraData['aadhaar_number'];
        }
      } else if (type == 'driving_license') {
        profileUpdates['driving_license_url'] = url;
        profileUpdates['driving_license_status'] = 'pending';
      }

      if (profileUpdates.length > 1) {
        await _client.from('profiles').update(profileUpdates).eq('id', userId);
        debugPrint('DocumentsService: Profiles table updated for $type');
      }

      debugPrint('DocumentsService: All records synced for $type');
    } catch (e) {
      debugPrint('DocumentsService: Error in uploadDocument: $e');
      if (e is StorageException) {
        debugPrint(
          'DocumentsService: Storage Error Details: ${e.message}, ${e.error}',
        );
        if ((e.message).toLowerCase().contains('bucket')) {
          throw Exception(
            'Upload failed: Storage bucket "$_bucketName" not found. Please create it in Supabase Storage.',
          );
        }
        if ((e.message).toLowerCase().contains('not authorized') ||
            (e.message).toLowerCase().contains('permission') ||
            (e.message).toLowerCase().contains('unauthorized')) {
          throw Exception(
            'Upload failed: Not authorized. Please check Supabase Storage policies for bucket "$_bucketName".',
          );
        }
        throw Exception('Upload failed: ${e.message}');
      } else if (e is PostgrestException) {
        debugPrint(
          'DocumentsService: DB Error Details: ${e.message}, ${e.details}',
        );
        throw Exception('Upload failed: ${e.message}');
      }
      rethrow;
    }
  }

  DocumentStatus _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return DocumentStatus.approved;
      case 'pending':
        return DocumentStatus.pending;
      case 'rejected':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.notUploaded;
    }
  }

  Future<bool> isVerificationComplete() async {
    final docs = await getDocumentsStatus();
    return docs.every((doc) => doc.status == DocumentStatus.approved);
  }
}
