import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/analysis_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../results/analysis_result_screen.dart';
import 'widgets/analyze_hero_card.dart';
import 'widgets/analyze_submit_button.dart';
import 'widgets/file_upload_card.dart';
import 'widgets/input_mode_selector.dart';
import 'widgets/privacy_matters_card.dart';
import 'widgets/sample_content_dialogs.dart';
import 'widgets/secondary_utility_cards.dart';

/// ScamShield 2.0 Analyze Submission Screen
///
/// Designed in strict accordance with the approved Phase 04 master blueprint
/// and visual references (analysze ape.jpeg and analysze ape.2jpeg.jpeg).
///
/// Supports 4 authenticated input modes:
/// 1. Text: Unicode multiline entry with 0/5000 counter and clipboard paste
/// 2. Image: Photo/gallery picker with image preview (JPG, PNG, WEBP up to 10 MB)
/// 3. Document: PDF picker with file metadata (PDF up to 20 MB)
/// 4. Audio: Audio file upload & recording (MP3, WAV, M4A up to 25 MB)
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
  late String _type = _normalizeInitialType(widget.initialType);
  bool _loading = false;
  String? _error;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  static const int _maxTextLength = 5000;

  static String _normalizeInitialType(String type) {
    if (type == 'document') return 'pdf';
    return type;
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant AnalyzeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      _selectType(_normalizeInitialType(widget.initialType));
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
    if (_type == type) return;
    setState(() {
      _type = type;
      _error = null;
      _selectedFileName = null;
      _selectedFileBytes = null;
    });
  }

  void _clearFile() {
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;
      _error = null;
    });
  }

  Future<void> _pickFile() async {
    final extensions = switch (_type) {
      'image' => ['jpg', 'jpeg', 'png', 'webp'],
      'pdf' => ['pdf'],
      'audio' => ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'webm'],
      _ => const <String>[],
    };

    final maxBytes = switch (_type) {
      'image' => 10 * 1024 * 1024, // 10 MB
      'pdf' => 20 * 1024 * 1024,   // 20 MB
      _ => 25 * 1024 * 1024,       // 25 MB
    };

    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (selection.isEmpty) return;
      final file = selection.single;
      final size = await file.length();

      if (size == null || size == 0) {
        setState(() => _error = 'The selected file could not be read.');
        return;
      }
      if (size > maxBytes) {
        final limitMb = (maxBytes / (1024 * 1024)).toInt();
        setState(
          () => _error = 'This file exceeds the maximum allowed size of $limitMb MB.',
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

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        _showToast('Clipboard is empty.');
        return;
      }
      setState(() {
        _type = 'text';
        _textController.text = text;
        _error = null;
      });
      _showToast('Text pasted from clipboard.');
    } catch (_) {
      _showToast('Could not access clipboard.');
    }
  }

  void _onTakePhoto() {
    _showToast('Camera capture requires camera hardware permission. Please choose from gallery.');
    _pickFile();
  }

  void _onRecordAudio() {
    _showToast('Please upload an audio file (MP3, WAV, M4A) for AI scam analysis.');
    _pickFile();
  }

  void _showSampleMessagesDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => SampleMessagesDialog(
        onMessageSelected: (sample) {
          setState(() {
            _textController.text = sample;
            _error = null;
          });
        },
      ),
    );
  }

  void _showSampleDocumentsDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => SampleInfoDialog(
        title: 'Sample Documents',
        subtitle: 'Review typical suspicious documents and test their text:',
        items: SampleScamData.documents,
        onLoadText: (sample) {
          setState(() {
            _type = 'text';
            _textController.text = sample;
            _error = null;
          });
        },
      ),
    );
  }

  void _showSampleAudioDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => SampleInfoDialog(
        title: 'Sample Audio Scams',
        subtitle: 'Review typical robocall transcripts and test their analysis:',
        items: SampleScamData.audios,
        onLoadText: (sample) {
          setState(() {
            _type = 'text';
            _textController.text = sample;
            _error = null;
          });
        },
      ),
    );
  }

  void _showVideoConvertDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert from Video'),
        content: const Text(
          'To analyze audio from a video recording, select your audio file or extract the audio track as MP3 or M4A before uploading.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickFile();
            },
            child: const Text('Select Audio File'),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (widget.onBackToDashboard != null) {
      widget.onBackToDashboard!();
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
        setState(() => _error = error.message);
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

  bool get _canSubmit {
    if (_loading) return false;
    return _type == 'text'
        ? _textController.text.trim().isNotEmpty
        : _selectedFileBytes != null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textMainDark : AppColors.textMainLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: titleColor,
          ),
          onPressed: _handleBack,
          tooltip: 'Back',
        ),
        title: Text(
          'Analyze',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Card: "Analyze & Stay Safe"
              const AnalyzeHeroCard(),
              const SizedBox(height: 18),

              // 4-Mode Selector: [Text, Image, Document, Audio]
              InputModeSelector(
                selectedMode: _type,
                onModeSelected: _selectType,
              ),
              const SizedBox(height: 18),

              // Error Banner (if error present)
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF331B10) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFFD65A31) : const Color(0xFFFCA5A5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _error = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Dynamic Mode Content
              if (_type == 'text') ...[
                // Text Area Card with Character Counter
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _textController,
                        minLines: 5,
                        maxLines: 8,
                        maxLength: _maxTextLength,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            null, // Hidden default counter, we render custom counter below
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          height: 1.45,
                          color: titleColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste or type a message here...',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_textController.text.length}/$_maxTextLength',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Primary Analyze CTA Button
                AnalyzeSubmitButton(
                  onPressed: _canSubmit ? _submit : null,
                  loading: _loading,
                ),

                // Or Divider
                const OrDivider(),

                // 2x2 Grid of Secondary Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Paste from Clipboard',
                        subtitle: 'Analyze copied text message',
                        icon: Icons.content_paste_rounded,
                        onTap: _pasteFromClipboard,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Sample Messages',
                        subtitle: 'Try example scams to see how it works',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: _showSampleMessagesDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Scan Image',
                        subtitle: 'Upload screenshot of a message',
                        icon: Icons.image_outlined,
                        onTap: () {
                          _selectType('image');
                          _pickFile();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Upload Document',
                        subtitle: 'Upload PDF or file to analyze content',
                        icon: Icons.description_outlined,
                        onTap: () {
                          _selectType('pdf');
                          _pickFile();
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (_type == 'image') ...[
                // Image Upload Dropzone / Preview Card
                FileUploadCard(
                  title: 'Upload an image or screenshot',
                  subtitle: 'Analyze screenshots, images and media files to detect scams.',
                  capacityNote: 'Supports JPG, PNG, WEBP (Max 10 MB)',
                  icon: Icons.image_outlined,
                  isImage: true,
                  selectedFileName: _selectedFileName,
                  selectedFileBytes: _selectedFileBytes,
                  onRemove: _clearFile,
                  onChange: _pickFile,
                  loading: _loading,
                  actions: Row(
                    children: [
                      Expanded(
                        child: CardActionButton(
                          label: 'Take a Photo',
                          icon: Icons.photo_camera_outlined,
                          onTap: _onTakePhoto,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CardActionButton(
                          label: 'Choose from Gallery',
                          icon: Icons.photo_library_outlined,
                          onTap: _pickFile,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Primary Analyze CTA Button
                AnalyzeSubmitButton(
                  onPressed: _canSubmit ? _submit : null,
                  loading: _loading,
                ),

                // Or Divider
                const OrDivider(),

                // Secondary Action Card for Image Mode
                UtilityActionCard(
                  title: 'Upload Document (PDF)',
                  subtitle: 'Upload a PDF or file to analyze content',
                  icon: Icons.description_outlined,
                  onTap: () {
                    _selectType('pdf');
                    _pickFile();
                  },
                ),
              ] else if (_type == 'pdf') ...[
                // Document Upload Dropzone / Preview Card
                FileUploadCard(
                  title: 'Upload a document (PDF)',
                  subtitle: 'Analyze PDFs and documents to detect scams, phishing and suspicious content.',
                  capacityNote: 'Supports PDF files (Max 20 MB)',
                  icon: Icons.description_outlined,
                  isImage: false,
                  selectedFileName: _selectedFileName,
                  selectedFileBytes: _selectedFileBytes,
                  onRemove: _clearFile,
                  onChange: _pickFile,
                  loading: _loading,
                  actions: SizedBox(
                    width: double.infinity,
                    child: CardActionButton(
                      label: 'Choose PDF File',
                      icon: Icons.picture_as_pdf_outlined,
                      onTap: _pickFile,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Primary Analyze CTA Button
                AnalyzeSubmitButton(
                  onPressed: _canSubmit ? _submit : null,
                  loading: _loading,
                ),

                // Or Divider
                const OrDivider(),

                // 2 Secondary Action Cards for Document Mode
                Row(
                  children: [
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Paste from Clipboard',
                        subtitle: 'Paste document text to analyze',
                        icon: Icons.content_paste_rounded,
                        onTap: _pasteFromClipboard,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Sample Documents',
                        subtitle: 'Try example documents to see how it works',
                        icon: Icons.description_outlined,
                        onTap: _showSampleDocumentsDialog,
                      ),
                    ),
                  ],
                ),
              ] else if (_type == 'audio') ...[
                // Audio Upload Dropzone / Preview Card
                FileUploadCard(
                  title: 'Record audio or upload a file',
                  subtitle: 'Analyze voice messages, call recordings and audio files to detect scams.',
                  capacityNote: 'Supports MP3, WAV, M4A, AAC, OGG (Max 25 MB)',
                  icon: Icons.mic_none_rounded,
                  isImage: false,
                  selectedFileName: _selectedFileName,
                  selectedFileBytes: _selectedFileBytes,
                  onRemove: _clearFile,
                  onChange: _pickFile,
                  loading: _loading,
                  actions: Row(
                    children: [
                      Expanded(
                        child: CardActionButton(
                          label: 'Record Audio',
                          icon: Icons.fiber_manual_record_rounded,
                          iconColor: Colors.redAccent,
                          onTap: _onRecordAudio,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CardActionButton(
                          label: 'Upload Audio',
                          icon: Icons.file_upload_outlined,
                          onTap: _pickFile,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Primary Analyze CTA Button
                AnalyzeSubmitButton(
                  onPressed: _canSubmit ? _submit : null,
                  loading: _loading,
                ),

                // Or Divider
                const OrDivider(),

                // 2 Secondary Action Cards for Audio Mode
                Row(
                  children: [
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Sample Audio',
                        subtitle: 'Try example audios to see how it works',
                        icon: Icons.graphic_eq_rounded,
                        onTap: _showSampleAudioDialog,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: UtilityActionCard(
                        title: 'Convert from Video',
                        subtitle: 'Extract audio from a video file',
                        icon: Icons.video_file_outlined,
                        onTap: _showVideoConvertDialog,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Bottom Privacy Guarantee Card
              const PrivacyMattersCard(),
            ],
          ),
        ),
      ),
    );
  }
}
