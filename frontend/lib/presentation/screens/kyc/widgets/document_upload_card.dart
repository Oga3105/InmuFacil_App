import 'dart:io';
import 'package:flutter/material.dart';

import 'package:inmufacil_frontend/presentation/providers/verification_provider.dart';

class DocumentUploadCard extends StatelessWidget {

  const DocumentUploadCard({
    super.key,
    required this.title,
    required this.onTap,
    this.imageFile,
    required this.status,
  });
  final String title;
  final VoidCallback onTap;
  final File? imageFile;
  final UploadStatus status;

  @override
  Widget build(BuildContext context) {
    bool hasImage = imageFile != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50], // Very light grey background
          border: Border.all(
            color: hasImage ? Colors.green : Colors.grey[300]!,
            width: hasImage ? 2 : 1,
            style: hasImage ? BorderStyle.solid : BorderStyle.solid, 
            // Ideally use DottedBorder here if package available, sticking to standard for now to avoid dep hell
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10), // Inner radius
                child: Image.file(
                  imageFile!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            
            // Overlay for content if not image, or overlay icon if success
            if (!hasImage)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                    Icons.camera_alt_outlined,
                    size: 48,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (status == UploadStatus.picking || status == UploadStatus.idle)
                  Text(
                    'Toca para escanear',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

             // Status Indicators
             if (status == UploadStatus.picking)
               const CircularProgressIndicator(),

             if (hasImage)
               Positioned(
                 top: 8,
                 right: 8,
                 child: Container(
                   padding: const EdgeInsets.all(4),
                   decoration: const BoxDecoration(
                     color: Colors.white,
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
