import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/glasses_api.dart';
import '../models/tripo_generation_job.dart';
import 'tripo_result_page.dart';

// ─── Palette ──────────────────────────────────────────────────────
class _C {
  static const obsidian   = Color(0xFF080C12);
  static const deepNavy   = Color(0xFF0D1420);
  static const surface    = Color(0xFF111827);
  static const card       = Color(0xFF161F2E);
  static const cardBorder = Color(0xFF1E2D45);
  static const chrome     = Color(0xFFB8C8DC);
  static const chromeDim  = Color(0xFF6B8099);
  static const electric   = Color(0xFF00A8FF);
  static const textPrim   = Color(0xFFEDF2F8);
  static const textSec    = Color(0xFF7A90A8);
  static const border     = Color(0xFF1E2D45);
  static const error      = Color(0xFFFF4D6A);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFF59E0B);
  static const purple     = Color(0xFF8B5CF6);
}

// ═══════════════════════════════════════════════════════════════════
// EXPLORE PAGE  =  2D → 3D GENERATOR  (logique backend originale)
// ═══════════════════════════════════════════════════════════════════
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with TickerProviderStateMixin {
  // ── Animations ─────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _pulseAnim;

  // ── API & state originaux ──────────────────────────────────────
  final GlassesApi   _glassesApi   = const GlassesApi();
  final ImagePicker  _imagePicker  = ImagePicker();

  Timer? _pollTimer;

  bool    _isSubmitting   = false;
  bool    _isLoadingJobs  = true;
  bool    _isPolling      = false;
  String? _inlineError;
  String? _statusMessage;

  XFile? _frontImage;
  XFile? _leftImage;
  XFile? _backImage;
  XFile? _rightImage;

  TripoGenerationJob?       _activeJob;
  List<TripoGenerationJob>  _jobs = <TripoGenerationJob>[];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _entryCtrl.forward();
    _loadJobs(); // original
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers originaux ──────────────────────────────────────────
  int get _selectedImagesCount {
    int count = 0;
    if (_frontImage != null) count++;
    if (_leftImage  != null) count++;
    if (_backImage  != null) count++;
    if (_rightImage != null) count++;
    return count;
  }

  bool get _canGenerate =>
      _frontImage != null && _selectedImagesCount >= 2 && !_isSubmitting;

  // ── _loadJobs original ─────────────────────────────────────────
  Future<void> _loadJobs() async {
    setState(() => _isLoadingJobs = true);
    try {
      final List<TripoGenerationJob> jobs = await _glassesApi.fetchTripoJobs();
      if (!mounted) return;
      setState(() => _jobs = jobs);
    } catch (_) {
      if (!mounted) return;
      setState(() => _inlineError ??= 'Could not load recent jobs.');
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingJobs = false);
    }
  }

  // ── _pickImage original ────────────────────────────────────────
  Future<void> _showImageSourceSheet(_UploadSlotType type) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _C.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 18),
                    decoration: BoxDecoration(
                      color: _C.cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add image',
                        style: TextStyle(
                          color: _C.textPrim,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose how you want to provide this view.',
                        style: TextStyle(
                          color: _C.textSec,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ImageSourceOption(
                    icon: Icons.photo_camera_outlined,
                    title: 'Take a Photo',
                    subtitle: 'Open the camera and capture a new image.',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _pickImage(type, ImageSource.camera);
                    },
                  ),
                  _ImageSourceOption(
                    icon: Icons.photo_library_outlined,
                    title: 'Choose from Gallery',
                    subtitle: 'Select an existing image from your library.',
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _pickImage(type, ImageSource.gallery);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(_UploadSlotType type, ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;
      setState(() {
        switch (type) {
          case _UploadSlotType.front:  _frontImage = picked; break;
          case _UploadSlotType.left:   _leftImage  = picked; break;
          case _UploadSlotType.back:   _backImage  = picked; break;
          case _UploadSlotType.right:  _rightImage = picked; break;
        }
        _inlineError = null;
      });
    } catch (_) {
      if (!mounted) return;
      final String sourceLabel =
          source == ImageSource.camera ? 'camera' : 'gallery';
      ScaffoldMessenger.of(context).showSnackBar(
        _styledSnack('Could not pick image from $sourceLabel.',
            icon: Icons.warning_amber_rounded, color: _C.error));
    }
  }

  // ── _removeImage original ──────────────────────────────────────
  void _removeImage(_UploadSlotType type) {
    setState(() {
      switch (type) {
        case _UploadSlotType.front:  _frontImage = null; break;
        case _UploadSlotType.left:   _leftImage  = null; break;
        case _UploadSlotType.back:   _backImage  = null; break;
        case _UploadSlotType.right:  _rightImage = null; break;
      }
    });
  }

  // ── _generateModel original ────────────────────────────────────
  Future<void> _generateModel() async {
    if (_frontImage == null) {
      setState(() => _inlineError = 'Front image is required.');
      return;
    }
    if (_selectedImagesCount < 2) {
      setState(() => _inlineError = 'Please select at least 2 images.');
      return;
    }
    setState(() {
      _isSubmitting  = true;
      _inlineError   = null;
      _statusMessage = 'Uploading views and creating 3D generation task...';
    });
    try {
      final Uint8List  frontBytes = await _frontImage!.readAsBytes();
      final Uint8List? leftBytes  = await _leftImage?.readAsBytes();
      final Uint8List? backBytes  = await _backImage?.readAsBytes();
      final Uint8List? rightBytes = await _rightImage?.readAsBytes();

      final TripoGenerationJob created = await _glassesApi.generateTripoModel(
        frontImageBytes: frontBytes,
        frontImageName: _frontImage!.name,
        leftImageBytes: leftBytes,
        leftImageName:  _leftImage?.name,
        backImageBytes: backBytes,
        backImageName:  _backImage?.name,
        rightImageBytes: rightBytes,
        rightImageName:  _rightImage?.name,
      );

      if (!mounted) return;
      setState(() {
        _activeJob     = created;
        _statusMessage = 'Generation started. Tracking job status...';
      });
      await _loadJobs();
      _startPolling(created.jobId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inlineError   = 'Could not start 3D generation. Please try again.';
        _statusMessage = null;
      });
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  // ── Polling original ───────────────────────────────────────────
  void _startPolling(int jobId) {
    _pollTimer?.cancel();
    setState(() => _isPolling = true);
    _pollTimer = Timer.periodic(
        const Duration(seconds: 5), (_) async => _refreshJobStatus(jobId));
    _refreshJobStatus(jobId);
  }

  Future<void> _refreshJobStatus(int jobId) async {
    try {
      final TripoGenerationJob job =
          await _glassesApi.fetchTripoJobStatus(jobId);
      if (!mounted) return;
      setState(() {
        _activeJob     = job;
        _statusMessage = _mapStatusMessage(job);
      });
      final String norm = job.status.toLowerCase();
      if (norm == 'success' || norm == 'failed') {
        _pollTimer?.cancel();
        setState(() => _isPolling = false);
        await _loadJobs();
      }
    } catch (_) {
      if (!mounted) return;
      _pollTimer?.cancel();
      setState(() {
        _isPolling   = false;
        _inlineError = 'Could not refresh generation status.';
      });
    }
  }

  String _mapStatusMessage(TripoGenerationJob job) {
    switch (job.status.toLowerCase()) {
      case 'pending':    return 'Job created and waiting to start.';
      case 'uploaded':   return 'Images uploaded successfully.';
      case 'processing': return 'Tripo is generating your 3D model...';
      case 'success':    return '3D model generated successfully.';
      case 'failed':
        return (job.errorMessage?.isNotEmpty == true)
            ? job.errorMessage! : '3D generation failed.';
      default: return 'Tracking generation status...';
    }
  }

  void _openJobResult(TripoGenerationJob job) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => TripoResultPage(job: job)));
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'success':    return _C.success;
      case 'failed':     return _C.error;
      case 'processing':
      case 'uploaded':
      case 'pending':    return _C.electric;
      default:           return _C.textSec;
    }
  }

  SnackBar _styledSnack(String msg,
      {required IconData icon, Color color = _C.electric}) {
    return SnackBar(
      content: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(color: _C.textPrim, fontSize: 13))),
      ]),
      backgroundColor: _C.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5))),
      margin: const EdgeInsets.all(16),
    );
  }

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: _buildAppBar(),
      body: Stack(children: [
        // Halo animé
        Positioned(top: -80, right: -60,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _C.electric.withOpacity(0.11 * _pulseAnim.value),
                  Colors.transparent,
                ])),
            ),
          ),
        ),
        Positioned(bottom: -120, left: -80,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _C.purple.withOpacity(0.08), Colors.transparent,
              ])),
          ),
        ),
        // Grille hexagonale
        Positioned.fill(child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) =>
                CustomPaint(painter: _HexGridPainter(_pulseAnim.value)),
          ),
        )),

        // Contenu
        SafeArea(child: FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            primary: false,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              // ── Hero banner ───────────────────────────────
              _HeroBanner(),
              const SizedBox(height: 20),

              // ── Uploader ──────────────────────────────────
              _SectionLabel(
                title: '2D → 3D Generator',
                subtitle: 'Upload front + extra views pour générer un modèle Tripo 3D',
              ),
              const SizedBox(height: 12),

              _UploadPanel(
                frontImage: _frontImage,
                leftImage:  _leftImage,
                backImage:  _backImage,
                rightImage: _rightImage,
                onPick:        _showImageSourceSheet,
                onRemove:      _removeImage,
                onGenerate:    _generateModel,
                canGenerate:   _canGenerate,
                isSubmitting:  _isSubmitting,
                inlineError:   _inlineError,
                selectedCount: _selectedImagesCount,
              ),
              const SizedBox(height: 16),

              // ── Status panel ──────────────────────────────
              if (_activeJob != null || _statusMessage != null) ...[
                _StatusPanel(
                  job:           _activeJob,
                  statusMessage: _statusMessage,
                  isPolling:     _isPolling,
                  statusColor:   _statusColor(_activeJob?.status),
                  onOpenResult:  _activeJob != null &&
                      _activeJob!.status.toLowerCase() == 'success'
                      ? () => _openJobResult(_activeJob!)
                      : null,
                ),
                const SizedBox(height: 20),
              ],

              // ── Jobs récents ──────────────────────────────
              _SectionLabel(
                title: 'Générations récentes',
                subtitle: 'Vos derniers jobs de transformation 2D → 3D',
              ),
              const SizedBox(height: 12),

              if (_isLoadingJobs)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(_C.electric),
                    strokeWidth: 2.5),
                ))
              else if (_jobs.isEmpty)
                _EmptyState(
                  title: 'Aucun job pour l\'instant',
                  subtitle: 'Uploadez au moins 2 vues pour créer votre premier modèle 3D.',
                )
              else
                Column(
                  children: _jobs.take(6).map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _JobTile(
                      job: job,
                      color: _statusColor(job.status),
                      onTap: () => _openJobResult(job),
                    ),
                  )).toList(),
                ),
            ],
          ),
        )),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.deepNavy,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('2D → 3D', style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.w900, color: _C.textPrim, letterSpacing: 2)),
        Text('VTON GENERATOR', style: TextStyle(fontSize: 9,
            color: _C.electric, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        GestureDetector(
          onTap: _loadJobs,
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.electric.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.electric.withOpacity(0.4))),
            child: Row(children: const [
              Icon(Icons.refresh_rounded, color: _C.electric, size: 13),
              SizedBox(width: 4),
              Text('Refresh', style: TextStyle(fontSize: 10,
                  color: _C.electric, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent, _C.electric, Colors.transparent])))),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════

// ── Hero banner ───────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.electric.withOpacity(0.14), _C.purple.withOpacity(0.10)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.electric.withOpacity(0.25), width: 1),
        boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.10),
            blurRadius: 24, offset: const Offset(0, 8))]),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.electric.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.electric.withOpacity(0.3))),
            child: const Text('TRIPO AI · 3D GENERATION', style: TextStyle(
                fontSize: 9, color: _C.electric,
                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 12),
          const Text('Transformez vos\nvues 2D en modèle 3D',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                color: _C.textPrim, height: 1.2)),
          const SizedBox(height: 8),
          const Text('Uploadez la vue face (obligatoire) + au moins\n1 autre angle pour démarrer la génération.',
            style: TextStyle(fontSize: 12, color: _C.textSec, height: 1.5)),
        ])),
        const SizedBox(width: 16),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0078CC), _C.electric],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: _C.electric.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 5))]),
          child: const Icon(Icons.view_in_ar_rounded,
              color: Colors.white, size: 30)),
      ]),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title, subtitle;
  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 3, height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.electric, Color(0xFF0070B8)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16,
            fontWeight: FontWeight.w800, color: _C.textPrim)),
      ]),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 13),
        child: Text(subtitle, style: const TextStyle(
            fontSize: 11, color: _C.textSec, height: 1.4))),
    ]);
  }
}

// ── Upload panel ──────────────────────────────────────────────────
class _UploadPanel extends StatelessWidget {
  final XFile? frontImage, leftImage, backImage, rightImage;
  final Future<void> Function(_UploadSlotType) onPick;
  final void Function(_UploadSlotType) onRemove;
  final VoidCallback onGenerate;
  final bool canGenerate, isSubmitting;
  final String? inlineError;
  final int selectedCount;

  const _UploadPanel({
    required this.frontImage, required this.leftImage,
    required this.backImage,  required this.rightImage,
    required this.onPick,     required this.onRemove,
    required this.onGenerate, required this.canGenerate,
    required this.isSubmitting, required this.inlineError,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25),
            blurRadius: 18, offset: const Offset(0, 8))]),
      child: Column(children: [
        // Header
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _C.electric.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _C.electric.withOpacity(0.3))),
            child: const Icon(Icons.add_photo_alternate_outlined,
                color: _C.electric, size: 20)),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Multi-view upload', style: TextStyle(
                color: _C.textPrim, fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Face obligatoire · min. 2 vues au total',
                style: TextStyle(color: _C.textSec, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 16),

        // Grid 4 slots
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: [
            _UploadSlot(label: 'Face', required: true,
                file: frontImage,
                onPick: () => onPick(_UploadSlotType.front),
                onRemove: () => onRemove(_UploadSlotType.front)),
            _UploadSlot(label: 'Gauche', file: leftImage,
                onPick: () => onPick(_UploadSlotType.left),
                onRemove: () => onRemove(_UploadSlotType.left)),
            _UploadSlot(label: 'Dos', file: backImage,
                onPick: () => onPick(_UploadSlotType.back),
                onRemove: () => onRemove(_UploadSlotType.back)),
            _UploadSlot(label: 'Droite', file: rightImage,
                onPick: () => onPick(_UploadSlotType.right),
                onRemove: () => onRemove(_UploadSlotType.right)),
          ],
        ),
        const SizedBox(height: 14),

        // Compteur vues
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _C.deepNavy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.cardBorder)),
          child: Row(children: [
            const Icon(Icons.photo_library_outlined,
                color: _C.chromeDim, size: 16),
            const SizedBox(width: 8),
            Text('Vues sélectionnées : $selectedCount / 4',
                style: const TextStyle(
                    color: _C.textPrim, fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            // Indicateurs
            Row(children: List.generate(4, (i) => Container(
              width: 6, height: 6, margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < selectedCount
                    ? _C.success : _C.cardBorder),
            ))),
          ]),
        ),

        // Erreur inline
        if (inlineError != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _C.error.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.error.withOpacity(0.35))),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: _C.error, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(inlineError!,
                  style: const TextStyle(
                      color: _C.error, fontSize: 12,
                      fontWeight: FontWeight.w600))),
            ]),
          ),
        ],
        const SizedBox(height: 16),

        // Bouton Generate
        _GenerateButton(
            canGenerate: canGenerate, isSubmitting: isSubmitting,
            onTap: onGenerate),
      ]),
    );
  }
}

// ── Upload slot ───────────────────────────────────────────────────
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Material(
        color: _C.deepNavy,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _C.electric.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.electric.withOpacity(0.28)),
                  ),
                  child: Icon(icon, color: _C.electric, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _C.textPrim,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _C.textSec,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _C.chromeDim,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadSlot extends StatefulWidget {
  final String label;
  final bool required;
  final XFile? file;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;

  const _UploadSlot({
    required this.label, this.required = false,
    required this.file, required this.onPick, required this.onRemove,
  });

  @override State<_UploadSlot> createState() => _UploadSlotState();
}
class _UploadSlotState extends State<_UploadSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool hasFile = widget.file != null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _pressed ? _C.deepNavy.withOpacity(0.7) : _C.deepNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? _C.electric.withOpacity(0.6)
                : _pressed ? _C.electric.withOpacity(0.3) : _C.cardBorder,
            width: hasFile ? 1.5 : 1),
          boxShadow: hasFile ? [BoxShadow(
              color: _C.electric.withOpacity(0.12),
              blurRadius: 10, offset: const Offset(0, 3))] : []),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            // Label + bouton remove
            Row(children: [
              Text(
                widget.required ? '${widget.label} *' : widget.label,
                style: TextStyle(
                  color: hasFile ? _C.electric : _C.textSec,
                  fontSize: 11, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
              const Spacer(),
              if (hasFile)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _C.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: _C.error)),
                ),
            ]),
            const SizedBox(height: 8),

            // Image ou placeholder
            Expanded(child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.cardBorder),
                image: hasFile ? DecorationImage(
                    image: NetworkImage(widget.file!.path),
                    fit: BoxFit.cover) : null),
              child: hasFile ? null : Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: _C.chromeDim, size: 24),
                const SizedBox(height: 6),
                const Text('Choisir', style: TextStyle(
                    color: _C.textSec, fontSize: 10)),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── Generate button ───────────────────────────────────────────────
class _GenerateButton extends StatefulWidget {
  final bool canGenerate, isSubmitting;
  final VoidCallback onTap;
  const _GenerateButton({required this.canGenerate,
      required this.isSubmitting, required this.onTap});
  @override State<_GenerateButton> createState() => _GenerateButtonState();
}
class _GenerateButtonState extends State<_GenerateButton> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (widget.canGenerate) setState(() => _p = true); },
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: widget.canGenerate ? widget.onTap : null,
      child: AnimatedScale(scale: _p ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 54, width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.canGenerate
                  ? const [Color(0xFF0078CC), _C.electric, Color(0xFF00C8FF)]
                  : [_C.chromeDim, _C.chromeDim],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.canGenerate ? [BoxShadow(
                color: _C.electric.withOpacity(_p ? 0.2 : 0.38),
                blurRadius: _p ? 10 : 22,
                offset: const Offset(0, 5))] : []),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 0, left: 16, right: 16,
              child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent, Colors.white24, Colors.transparent])))),
            widget.isSubmitting
                ? const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white))),
                    SizedBox(width: 12),
                    Text('Génération en cours…', style: TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w700)),
                  ])
                : const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('GÉNÉRER LE MODÈLE 3D', style: TextStyle(
                        color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ]),
          ]),
        ),
      ),
    );
  }
}

// ── Status panel ──────────────────────────────────────────────────
class _StatusPanel extends StatelessWidget {
  final TripoGenerationJob? job;
  final String? statusMessage;
  final bool isPolling;
  final Color statusColor;
  final VoidCallback? onOpenResult;

  const _StatusPanel({required this.job, required this.statusMessage,
      required this.isPolling, required this.statusColor,
      required this.onOpenResult});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: statusColor.withOpacity(0.25), width: 1),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: statusColor)),
          const SizedBox(width: 8),
          const Text('Statut de génération', style: TextStyle(
              color: _C.textPrim, fontWeight: FontWeight.w800, fontSize: 15)),
          const Spacer(),
          if (isPolling)
            SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(statusColor))),
        ]),
        const SizedBox(height: 12),

        if (job != null) ...[
          _StatusRow(label: 'Job ID', value: '${job!.jobId}'),
          const SizedBox(height: 6),
          _StatusRow(label: 'Status', value: job!.displayStatus,
              valueColor: statusColor),
          if ((job!.taskId ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            _StatusRow(label: 'Task ID', value: job!.taskId ?? ''),
          ],
          if ((job!.errorMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.error.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.error.withOpacity(0.3))),
              child: Text(job!.errorMessage!,
                  style: const TextStyle(color: _C.error, fontSize: 12))),
          ],
        ],

        if (statusMessage != null) ...[
          const SizedBox(height: 10),
          Text(statusMessage!, style: const TextStyle(
              color: _C.textSec, height: 1.45, fontSize: 12)),
        ],

        if (onOpenResult != null) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onOpenResult,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: _C.success.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _C.success.withOpacity(0.4), width: 1.5)),
              child: const Row(
                  mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.open_in_new_rounded,
                    color: _C.success, size: 16),
                SizedBox(width: 8),
                Text('Voir le résultat 3D', style: TextStyle(
                    color: _C.success, fontSize: 13,
                    fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label, value; final Color? valueColor;
  const _StatusRow({required this.label, required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label : ', style: const TextStyle(
          color: _C.textSec, fontSize: 12)),
      Flexible(child: Text(value, style: TextStyle(
          color: valueColor ?? _C.textPrim,
          fontSize: 12, fontWeight: FontWeight.w700))),
    ]);
  }
}

// ── Job tile ──────────────────────────────────────────────────────
class _JobTile extends StatefulWidget {
  final TripoGenerationJob job;
  final Color color;
  final VoidCallback onTap;
  const _JobTile({required this.job, required this.color,
      required this.onTap});
  @override State<_JobTile> createState() => _JobTileState();
}
class _JobTileState extends State<_JobTile> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hov = true),
        onExit: (_) => setState(() => _hov = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hov ? _C.card : _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hov
                  ? widget.color.withOpacity(0.35) : _C.cardBorder)),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.color.withOpacity(0.3))),
              child: Icon(Icons.view_in_ar_outlined,
                  color: widget.color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Job #${widget.job.jobId}',
                  style: const TextStyle(color: _C.textPrim,
                      fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 4),
              Text(widget.job.displayStatus,
                  style: TextStyle(color: widget.color,
                      fontWeight: FontWeight.w600, fontSize: 12)),
              if ((widget.job.modelUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 3),
                const Text('Modèle 3D disponible', style: TextStyle(
                    color: _C.textSec, fontSize: 11)),
              ],
            ])),
            Icon(Icons.chevron_right_rounded,
                color: _hov ? widget.color : _C.chromeDim),
          ]),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String title, subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder)),
      child: Column(children: [
        const Icon(Icons.inbox_outlined, color: _C.chromeDim, size: 40),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: _C.textPrim,
            fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center,
            style: const TextStyle(color: _C.textSec, height: 1.5, fontSize: 12)),
      ]),
    );
  }
}

// ── Enum ──────────────────────────────────────────────────────────
enum _UploadSlotType { front, left, back, right }

// ── HexGrid painter ───────────────────────────────────────────────
class _HexGridPainter extends CustomPainter {
  final double opacity;
  const _HexGridPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.electric.withOpacity(0.018 * opacity)
      ..style = PaintingStyle.stroke ..strokeWidth = 0.5;
    const r = 40.0; const dx = r * 1.732; const dy = r * 1.5;
    int row = 0;
    for (double y = -r; y < size.height + r; y += dy) {
      final off = row.isEven ? 0.0 : dx / 2;
      for (double x = -r + off; x < size.width + r; x += dx) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (math.pi / 180) * (60 * i - 30);
          final pt = Offset(x + r * math.cos(a), y + r * math.sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close(); canvas.drawPath(path, paint);
      }
      row++;
    }
  }
  @override bool shouldRepaint(_HexGridPainter old) => old.opacity != opacity;
}
