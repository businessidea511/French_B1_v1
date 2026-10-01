import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

enum PhotoImportMode { fullLesson, exercisesOnly }

/// The pages collected by [showPhotoPagesSheet].
class PhotoImportRequest {
  final List<String> base64Images;
  final String mimeType;
  final PhotoImportMode mode;
  final String? instructions;

  const PhotoImportRequest({
    required this.base64Images,
    required this.mimeType,
    required this.mode,
    this.instructions,
  });
}

// Photos are sent as base64 in one request; Vercel functions accept at most
// 4.5 MB, so keep the raw total comfortably below that after base64 (+33%).
const int _maxTotalBytes = 3 * 1024 * 1024;
const int _maxPages = 10;

/// Bottom sheet that collects textbook pages one by one (camera or gallery),
/// shows them as numbered thumbnails, and returns them in page order.
/// [mode] only changes the wording; the caller decides what to do with it.
/// Returns null if the admin closes the sheet.
Future<PhotoImportRequest?> showPhotoPagesSheet(
  BuildContext context, {
  required String title,
  required PhotoImportMode mode,
  bool askInstructions = true,
}) {
  return showModalBottomSheet<PhotoImportRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _PhotoPagesSheet(
      title: title,
      mode: mode,
      askInstructions: askInstructions,
    ),
  );
}

class _Page {
  final Uint8List bytes;
  const _Page(this.bytes);
}

class _PhotoPagesSheet extends StatefulWidget {
  final String title;
  final PhotoImportMode mode;
  final bool askInstructions;

  const _PhotoPagesSheet({
    required this.title,
    required this.mode,
    required this.askInstructions,
  });

  @override
  State<_PhotoPagesSheet> createState() => _PhotoPagesSheetState();
}

class _PhotoPagesSheetState extends State<_PhotoPagesSheet> {
  final List<_Page> _pages = [];
  final TextEditingController _instructions = TextEditingController();
  bool _picking = false;

  int get _totalBytes => _pages.fold(0, (sum, p) => sum + p.bytes.length);
  bool get _tooBig => _totalBytes > _maxTotalBytes;

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _add(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      // Sharp enough for small textbook print, small enough to send ~10 pages.
      const maxSide = 1400.0;
      const quality = 60;
      final List<XFile> files;
      if (source == ImageSource.gallery) {
        files = await picker.pickMultiImage(maxWidth: maxSide, maxHeight: maxSide, imageQuality: quality);
      } else {
        final photo = await picker.pickImage(
            source: source, maxWidth: maxSide, maxHeight: maxSide, imageQuality: quality);
        files = photo == null ? [] : [photo];
      }
      for (final f in files) {
        if (_pages.length >= _maxPages) break;
        _pages.add(_Page(await f.readAsBytes()));
      }
    } catch (e) {
      debugPrint('Photo pick error: $e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _submit() {
    final first = _pages.first.bytes;
    final isPng = first.length > 4 && first[0] == 0x89 && first[1] == 0x50 && first[2] == 0x4E && first[3] == 0x47;
    final text = _instructions.text.trim();
    Navigator.pop(
      context,
      PhotoImportRequest(
        base64Images: _pages.map((p) => base64Encode(p.bytes)).toList(),
        mimeType: isPng ? 'image/png' : 'image/jpeg',
        mode: widget.mode,
        instructions: text.isEmpty ? null : text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mb = (_totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final maxMb = (_maxTotalBytes / (1024 * 1024)).toStringAsFixed(0);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(
                widget.mode == PhotoImportMode.exercisesOnly
                    ? 'Add the exercise pages. Every exercise becomes an interactive exercise in this lesson.'
                    : 'Add the lesson pages in order. You can take several photos one after another.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),

            // Page thumbnails
            if (_pages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: _pages.length,
                  onReorder: (from, to) => setState(() {
                    if (to > from) to -= 1;
                    _pages.insert(to, _pages.removeAt(from));
                  }),
                  itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
                    key: ObjectKey(_pages[i]),
                    index: i,
                    child: _thumbnail(i),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('No pages yet', style: TextStyle(color: AppTheme.textTertiary)),
              ),
            const SizedBox(height: 8),
            Text(
              '${_pages.length} / $_maxPages pages · $mb / $maxMb MB'
              '${_pages.length > 1 ? ' · long-press a page to reorder' : ''}',
              style: TextStyle(color: _tooBig ? AppTheme.error : AppTheme.textTertiary, fontSize: 12),
            ),
            if (_tooBig)
              const Text('Too large to send at once. Remove a page or split it into two imports.',
                  style: TextStyle(color: AppTheme.error, fontSize: 12)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking || _pages.length >= _maxPages ? null : () => _add(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking || _pages.length >= _maxPages ? null : () => _add(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            if (widget.askInstructions) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _instructions,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Optional instructions (e.g. "only exercise 3 and 4")',
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pages.isEmpty || _tooBig || _picking ? null : _submit,
              icon: _picking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(widget.mode == PhotoImportMode.exercisesOnly
                  ? 'Import exercises from ${_pages.length} page${_pages.length == 1 ? '' : 's'}'
                  : 'Create from ${_pages.length} page${_pages.length == 1 ? '' : 's'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(int i) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_pages[i].bytes, width: 90, height: 120, fit: BoxFit.cover),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primary,
              child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
              onPressed: () => setState(() => _pages.removeAt(i)),
            ),
          ),
        ],
      ),
    );
  }
}
