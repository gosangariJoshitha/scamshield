import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/analysis_service.dart';
import '../../services/api_service.dart';
import '../results/analysis_result_screen.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({
    required this.analysisService,
    required this.initialType,
    required this.onSessionExpired,
    required this.onAnalysisCompleted,
    this.onBackToDashboard,
    super.key,
  });

  final AnalysisService analysisService;
  final String initialType;
  final Future<void> Function() onSessionExpired;
  final VoidCallback onAnalysisCompleted;
  final VoidCallback? onBackToDashboard;

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _textController = TextEditingController();
  late String _type = widget.initialType;
  bool _loading = false;
  String? _error;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant AnalyzeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      _selectType(widget.initialType);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _selectType(String type) {
    setState(() {
      _type = type;
      _error = null;
      _selectedFileName = null;
      _selectedFileBytes = null;
    });
  }

  Future<void> _pickFile() async {
    final extensions = switch (_type) {
      'image' => ['jpg', 'jpeg', 'png', 'webp'],
      'pdf' => ['pdf'],
      'audio' => ['mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac', 'webm'],
      _ => const <String>[],
    };
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (selection.isEmpty) return;
      final file = selection.single;
      final size = await file.length();
      final maxBytes = switch (_type) {
        'image' => 10 * 1024 * 1024,
        'pdf' => 20 * 1024 * 1024,
        _ => 25 * 1024 * 1024,
      };
      if (size == null || size == 0) {
        setState(() => _error = 'The selected file could not be read.');
        return;
      }
      if (size > maxBytes) {
        setState(
          () => _error = 'This file is larger than the supported size limit.',
        );
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedFileName = file.name;
        _selectedFileBytes = bytes;
        _error = null;
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'Could not open the file picker. Please retry.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_type == 'text' && _textController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a message or link to analyze.');
      return;
    }
    if (_type != 'text' && _selectedFileBytes == null) {
      setState(() => _error = 'Choose a file before starting the analysis.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = _type == 'text'
          ? await widget.analysisService.analyzeText(
              _textController.text.trim(),
            )
          : await widget.analysisService.analyzeFile(
              type: _type,
              filename: _selectedFileName!,
              bytes: _selectedFileBytes!,
            );
      if (!mounted) return;
      widget.onAnalysisCompleted();
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisResultScreen(
            analysis: result,
            onBackToDashboard: widget.onBackToDashboard,
            onAnalyzeAnother: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await widget.onSessionExpired();
        return;
      }
      if (mounted) {
        setState(
          () =>
              _error = 'We couldn’t complete this analysis. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to complete the analysis. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isText = _type == 'text';
    final title = switch (_type) {
      'image' => 'Analyze an image',
      'pdf' => 'Analyze a PDF',
      'audio' => 'Analyze audio',
      _ => 'Analyze text',
    };
    final description = switch (_type) {
      'image' => 'Choose a screenshot or image containing suspicious content.',
      'pdf' => 'Choose a PDF document to inspect its contents.',
      'audio' =>
        'Choose a voice message or audio file for transcription and analysis.',
      _ => 'Paste a suspicious message, email, or link for analysis.',
    };
    final inputIcon = switch (_type) {
      'image' => Icons.image_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      'audio' => Icons.graphic_eq_rounded,
      _ => Icons.chat_bubble_outline_rounded,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Analyze')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypeChip(
                  type: 'text',
                  selected: _type,
                  onSelected: _selectType,
                ),
                _TypeChip(
                  type: 'image',
                  selected: _type,
                  onSelected: _selectType,
                ),
                _TypeChip(
                  type: 'pdf',
                  selected: _type,
                  onSelected: _selectType,
                ),
                _TypeChip(
                  type: 'audio',
                  selected: _type,
                  onSelected: _selectType,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.035),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(inputIcon, color: colors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isText ? 'MESSAGE OR LINK' : 'SELECTED FILE',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.45,
                              ),
                        ),
                      ),
                      if (!isText)
                        Text(
                          _type == 'image'
                              ? 'Up to 10 MB'
                              : _type == 'pdf'
                              ? 'Up to 20 MB'
                              : 'Up to 25 MB',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isText)
                    TextField(
                      controller: _textController,
                      minLines: 6,
                      maxLines: 10,
                      maxLength: 20000,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText:
                            'Paste a suspicious message, email, or link here…',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    )
                  else ...[
                    if (_selectedFileName != null) ...[
                      _SelectedFilePreview(
                        type: _type,
                        name: _selectedFileName!,
                        bytes: _selectedFileBytes!,
                        onChange: _loading ? null : _pickFile,
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _pickFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Choose file'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: _error!),
            ],
            if (_loading) ...[
              const SizedBox(height: 14),
              _AnalysisProgressCard(type: _type),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_loading ? 'ANALYZING…' : 'ANALYZE'),
            ),
            const SizedBox(height: 16),
            Text(
              'Your submission is sent securely to ScamShield for analysis. Avoid submitting passwords or payment card details.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    if (_loading) return false;
    return _type == 'text'
        ? _textController.text.trim().isNotEmpty
        : _selectedFileBytes != null;
  }
}

class _SelectedFilePreview extends StatelessWidget {
  const _SelectedFilePreview({
    required this.type,
    required this.name,
    required this.bytes,
    required this.onChange,
  });

  final String type;
  final String name;
  final Uint8List bytes;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (type) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'audio' => Icons.graphic_eq_rounded,
      _ => Icons.insert_drive_file_outlined,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (type == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 42, color: colors.primary),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, size: 19, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _formatFileSize(bytes.length),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Change file'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisProgressCard extends StatelessWidget {
  const _AnalysisProgressCard({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label:
          'Analysis in progress. Your ${type == 'text' ? 'message' : type} is being checked.',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyzing your submission',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 11),
            const LinearProgressIndicator(),
            const SizedBox(height: 9),
            Text(
              'Detailed step-by-step progress is not available. ScamShield will show your result when the analysis is complete.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  final String type;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(type.toUpperCase()),
      selected: type == selected,
      onSelected: (_) => onSelected(type),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
    );
  }
}
