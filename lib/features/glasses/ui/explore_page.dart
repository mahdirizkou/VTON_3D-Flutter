import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/glasses_api.dart';
import '../models/tripo_generation_job.dart';
import 'tripo_result_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _pulseAnim;

  final GlassesApi _glassesApi = const GlassesApi();
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _pollTimer;

  bool _isSubmitting = false;
  bool _isLoadingJobs = true;
  bool _isPolling = false;
  String? _inlineError;
  String? _statusMessage;

  XFile? _frontImage;
  XFile? _leftImage;
  XFile? _backImage;
  XFile? _rightImage;

  TripoGenerationJob? _activeJob;
  List<TripoGenerationJob> _jobs = <TripoGenerationJob>[];

  final List<_StyleCard> _styles = const <_StyleCard>[
    _StyleCard('Aviator', Icons.flight_outlined, Color(0xFF00A8FF), 'Classic & timeless'),
    _StyleCard('Round', Icons.circle_outlined, Color(0xFF8B5CF6), 'Retro inspired'),
    _StyleCard('Square', Icons.crop_square_outlined, Color(0xFF00D4AA), 'Bold & modern'),
    _StyleCard('Cat Eye', Icons.visibility_outlined, Color(0xFFF59E0B), 'Elegant curves'),
    _StyleCard('Sport', Icons.sports_outlined, Color(0xFFFF4D6A), 'Performance'),
    _StyleCard('Rimless', Icons.remove_outlined, Color(0xFFB8C8DC), 'Minimalist'),
  ];

  final List<_TrendBadge> _trends = const <_TrendBadge>[
    _TrendBadge('Blue Light Block', Color(0xFF00A8FF)),
    _TrendBadge('Titanium Frame', Color(0xFFB8C8DC)),
    _TrendBadge('Gradient Lens', Color(0xFF8B5CF6)),
    _TrendBadge('Anti-UV 400', Color(0xFF00D4AA)),
    _TrendBadge('Flex Hinge', Color(0xFFF59E0B)),
    _TrendBadge('Photochromic', Color(0xFFFF4D6A)),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _entryCtrl.forward();
    _loadJobs();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _selectedImagesCount {
    int count = 0;
    if (_frontImage != null) count++;
    if (_leftImage != null) count++;
    if (_backImage != null) count++;
    if (_rightImage != null) count++;
    return count;
  }

  bool get _canGenerate => _frontImage != null && _selectedImagesCount >= 2 && !_isSubmitting;

  Future<void> _loadJobs() async {
    setState(() {
      _isLoadingJobs = true;
    });

    try {
      final List<TripoGenerationJob> jobs = await _glassesApi.fetchTripoJobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inlineError ??= 'Could not load recent jobs.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingJobs = false;
      });
    }
  }

  Future<void> _pickImage(_UploadSlotType type) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (picked == null || !mounted) return;

      setState(() {
        switch (type) {
          case _UploadSlotType.front:
            _frontImage = picked;
            break;
          case _UploadSlotType.left:
            _leftImage = picked;
            break;
          case _UploadSlotType.back:
            _backImage = picked;
            break;
          case _UploadSlotType.right:
            _rightImage = picked;
            break;
        }
        _inlineError = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image from gallery.')),
      );
    }
  }

  void _removeImage(_UploadSlotType type) {
    setState(() {
      switch (type) {
        case _UploadSlotType.front:
          _frontImage = null;
          break;
        case _UploadSlotType.left:
          _leftImage = null;
          break;
        case _UploadSlotType.back:
          _backImage = null;
          break;
        case _UploadSlotType.right:
          _rightImage = null;
          break;
      }
    });
  }

  Future<void> _generateModel() async {
    if (_frontImage == null) {
      setState(() {
        _inlineError = 'Front image is required.';
      });
      return;
    }

    if (_selectedImagesCount < 2) {
      setState(() {
        _inlineError = 'Please select at least 2 images in total.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
      _statusMessage = 'Uploading views and creating 3D generation task...';
    });

    try {
      final Uint8List frontBytes = await _frontImage!.readAsBytes();
      final Uint8List? leftBytes = await _leftImage?.readAsBytes();
      final Uint8List? backBytes = await _backImage?.readAsBytes();
      final Uint8List? rightBytes = await _rightImage?.readAsBytes();

      final TripoGenerationJob created = await _glassesApi.generateTripoModel(
        frontImageBytes: frontBytes,
        frontImageName: _frontImage!.name,
        leftImageBytes: leftBytes,
        leftImageName: _leftImage?.name,
        backImageBytes: backBytes,
        backImageName: _backImage?.name,
        rightImageBytes: rightBytes,
        rightImageName: _rightImage?.name,
      );

      if (!mounted) return;

      setState(() {
        _activeJob = created;
        _statusMessage = 'Generation started. Tracking job status...';
      });

      await _loadJobs();
      _startPolling(created.jobId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inlineError = 'Could not start 3D generation. Please try again.';
        _statusMessage = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _startPolling(int jobId) {
    _pollTimer?.cancel();

    setState(() {
      _isPolling = true;
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _refreshJobStatus(jobId);
    });

    _refreshJobStatus(jobId);
  }

  Future<void> _refreshJobStatus(int jobId) async {
    try {
      final TripoGenerationJob job = await _glassesApi.fetchTripoJobStatus(jobId);
      if (!mounted) return;

      setState(() {
        _activeJob = job;
        _statusMessage = _mapStatusMessage(job);
      });

      final String normalized = job.status.toLowerCase();
      if (normalized == 'success' || normalized == 'failed') {
        _pollTimer?.cancel();
        setState(() {
          _isPolling = false;
        });
        await _loadJobs();
      }
    } catch (_) {
      if (!mounted) return;
      _pollTimer?.cancel();
      setState(() {
        _isPolling = false;
        _inlineError = 'Could not refresh generation status.';
      });
    }
  }

  String _mapStatusMessage(TripoGenerationJob job) {
    switch (job.status.toLowerCase()) {
      case 'pending':
        return 'Job created and waiting to start.';
      case 'uploaded':
        return 'Images uploaded successfully.';
      case 'processing':
        return 'Tripo is generating your 3D model...';
      case 'success':
        return '3D model generated successfully.';
      case 'failed':
        return job.errorMessage?.isNotEmpty == true
            ? job.errorMessage!
            : '3D generation failed.';
      default:
        return 'Tracking generation status...';
    }
  }

  void _openJobResult(TripoGenerationJob job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripoResultPage(job: job),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'success':
        return const Color(0xFF00D4AA);
      case 'failed':
        return const Color(0xFFFF4D6A);
      case 'processing':
      case 'uploaded':
      case 'pending':
        return _C.electric;
      default:
        return _C.textSec;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.obsidian,
      appBar: AppBar(
        backgroundColor: _C.deepNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'EXPLORE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _C.textPrim,
                letterSpacing: 2.6,
              ),
            ),
            Text(
              'TRENDING FRAMES + 2D TO 3D',
              style: TextStyle(
                fontSize: 9,
                color: _C.electric,
                letterSpacing: 2.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.transparent, _C.electric, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                return Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        _C.electric.withOpacity(0.11 * _pulseAnim.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    _C.purple.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HexGridPainter(_pulseAnim),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: <Widget>[
                  const _HeroPanel(),
                  const SizedBox(height: 16),
                  const _StatsBar(),
                  const SizedBox(height: 20),
                  const _SectionHeader(
                    title: '2D to 3D Generator',
                    subtitle: 'Upload front + extra views to generate a Tripo 3D model',
                  ),
                  const SizedBox(height: 12),
                  _GeneratorPanel(
                    frontImage: _frontImage,
                    leftImage: _leftImage,
                    backImage: _backImage,
                    rightImage: _rightImage,
                    onPick: _pickImage,
                    onRemove: _removeImage,
                    onGenerate: _generateModel,
                    canGenerate: _canGenerate,
                    isSubmitting: _isSubmitting,
                    inlineError: _inlineError,
                    selectedCount: _selectedImagesCount,
                  ),
                  const SizedBox(height: 16),
                  if (_activeJob != null || _statusMessage != null)
                    _StatusPanel(
                      job: _activeJob,
                      statusMessage: _statusMessage,
                      isPolling: _isPolling,
                      statusColor: _statusColor(_activeJob?.status),
                      onOpenResult: _activeJob != null &&
                              (_activeJob!.status.toLowerCase() == 'success')
                          ? () => _openJobResult(_activeJob!)
                          : null,
                    ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Recent Generation Jobs',
                    subtitle: 'Your latest 2D to 3D model generations',
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingJobs)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_jobs.isEmpty)
                    const _EmptyDarkState(
                      title: 'No generation jobs yet',
                      subtitle: 'Upload at least two views to create your first 3D model.',
                    )
                  else
                    Column(
                      children: _jobs
                          .take(6)
                          .map((TripoGenerationJob job) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _JobTile(
                                  job: job,
                                  color: _statusColor(job.status),
                                  onTap: () => _openJobResult(job),
                                ),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Trend Signals',
                    subtitle: 'Materials and lens features trending now',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _trends
                        .map((_TrendBadge trend) => _TrendPill(data: trend))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Frame Styles',
                    subtitle: 'A curated grid of silhouettes to explore',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _styles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.12,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      return _StyleTile(data: _styles[index]);
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Editorial Picks',
                    subtitle: 'Visual directions for your next pair',
                  ),
                  const SizedBox(height: 12),
                  const _EditorialCard(
                    title: 'Studio Chrome',
                    subtitle: 'Sharp titanium lines with cool metallic finishes.',
                    accent: _C.electric,
                    icon: Icons.auto_awesome_outlined,
                  ),
                  const SizedBox(height: 12),
                  const _EditorialCard(
                    title: 'Soft Retro',
                    subtitle: 'Rounded rims, warm tints, and light acetate volumes.',
                    accent: _C.purple,
                    icon: Icons.blur_circular_outlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratorPanel extends StatelessWidget {
  const _GeneratorPanel({
    required this.frontImage,
    required this.leftImage,
    required this.backImage,
    required this.rightImage,
    required this.onPick,
    required this.onRemove,
    required this.onGenerate,
    required this.canGenerate,
    required this.isSubmitting,
    required this.inlineError,
    required this.selectedCount,
  });

  final XFile? frontImage;
  final XFile? leftImage;
  final XFile? backImage;
  final XFile? rightImage;
  final Future<void> Function(_UploadSlotType type) onPick;
  final void Function(_UploadSlotType type) onRemove;
  final VoidCallback onGenerate;
  final bool canGenerate;
  final bool isSubmitting;
  final String? inlineError;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.view_in_ar_outlined, color: _C.electric),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Multi-view upload',
                  style: TextStyle(
                    color: _C.textPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Front image is required. Add at least one more side to start generation.',
              style: TextStyle(
                color: _C.textSec,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.08,
            children: <Widget>[
              _UploadCard(
                title: 'Front',
                requiredField: true,
                file: frontImage,
                onPick: () => onPick(_UploadSlotType.front),
                onRemove: () => onRemove(_UploadSlotType.front),
              ),
              _UploadCard(
                title: 'Left',
                file: leftImage,
                onPick: () => onPick(_UploadSlotType.left),
                onRemove: () => onRemove(_UploadSlotType.left),
              ),
              _UploadCard(
                title: 'Back',
                file: backImage,
                onPick: () => onPick(_UploadSlotType.back),
                onRemove: () => onRemove(_UploadSlotType.back),
              ),
              _UploadCard(
                title: 'Right',
                file: rightImage,
                onPick: () => onPick(_UploadSlotType.right),
                onRemove: () => onRemove(_UploadSlotType.right),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.deepNavy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.cardBorder),
            ),
            child: Text(
              'Selected views: $selectedCount / 4',
              style: const TextStyle(
                color: _C.textPrim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (inlineError != null) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                inlineError!,
                style: const TextStyle(
                  color: Color(0xFFFF4D6A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canGenerate ? onGenerate : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isSubmitting ? 'Generating...' : 'Generate 3D Model'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.job,
    required this.statusMessage,
    required this.isPolling,
    required this.statusColor,
    required this.onOpenResult,
  });

  final TripoGenerationJob? job;
  final String? statusMessage;
  final bool isPolling;
  final Color statusColor;
  final VoidCallback? onOpenResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Generation Status',
                style: TextStyle(
                  color: _C.textPrim,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (isPolling)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (job != null) ...<Widget>[
            Text(
              'Job ID: ${job!.jobId}',
              style: const TextStyle(color: _C.textPrim, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Status: ${job!.displayStatus}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
            if ((job!.taskId ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Task ID: ${job!.taskId}',
                style: const TextStyle(color: _C.textSec),
              ),
            ],
            if ((job!.errorMessage ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                job!.errorMessage!,
                style: const TextStyle(color: Color(0xFFFF4D6A)),
              ),
            ],
          ],
          if (statusMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              statusMessage!,
              style: const TextStyle(color: _C.textSec, height: 1.45),
            ),
          ],
          if (onOpenResult != null) ...<Widget>[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onOpenResult,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Result'),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({
    required this.job,
    required this.color,
    required this.onTap,
  });

  final TripoGenerationJob job;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.30)),
              ),
              child: Icon(Icons.view_in_ar_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Job #${job.jobId}',
                    style: const TextStyle(
                      color: _C.textPrim,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.displayStatus,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((job.modelUrl ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    const Text(
                      '3D model available',
                      style: TextStyle(color: _C.textSec, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _C.textSec),
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.title,
    required this.file,
    required this.onPick,
    required this.onRemove,
    this.requiredField = false,
  });

  final String title;
  final XFile? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.deepNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: file != null ? _C.electric.withOpacity(0.55) : _C.cardBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      requiredField ? '$title *' : title,
                      style: const TextStyle(
                        color: _C.textPrim,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (file != null)
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: _C.textSec,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.cardBorder),
                    image: file != null
                        ? DecorationImage(
                            image: NetworkImage(file!.path),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: file == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.add_photo_alternate_outlined, color: _C.textSec, size: 28),
                            SizedBox(height: 8),
                            Text(
                              'Pick image',
                              style: TextStyle(color: _C.textSec, fontSize: 12),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDarkState extends StatelessWidget {
  const _EmptyDarkState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.inbox_outlined, color: _C.textSec, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _C.textPrim,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _C.textSec,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0D1420), Color(0xFF131E30), Color(0xFF0B111A)],
        ),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _C.electric.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _HeroBadge(),
          SizedBox(height: 16),
          Text(
            'Discover trends and turn 2D views into a 3D model.',
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: _C.textPrim,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Browse silhouettes, materials, and trend signals — then upload front and side views to generate a Tripo-ready 3D result.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _C.textSec,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _C.electric.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.electric.withOpacity(0.30)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Explore + Generate',
          style: TextStyle(
            fontSize: 10,
            color: _C.electric,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _C.textPrim,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: _C.textSec,
          ),
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.data,
  });

  final _StyleCard data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: data.color.withOpacity(0.28)),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const Spacer(),
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.textPrim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: _C.textSec,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialCard extends StatelessWidget {
  const _EditorialCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _C.textPrim,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _C.textSec,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.data});

  final _TrendBadge data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.color.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 11,
              color: data.color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.value, this.label);

  final String value;
  final String label;
}

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    const List<_StatItem> stats = <_StatItem>[
      _StatItem('500+', 'Frames'),
      _StatItem('50+', 'Brands'),
      _StatItem('3D', 'Try-On'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Row(
        children: List<Widget>.generate(stats.length * 2 - 1, (int index) {
          if (index.isOdd) {
            return Container(width: 1, height: 32, color: _C.cardBorder);
          }

          final _StatItem stat = stats[index ~/ 2];
          return Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  stat.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _C.electric,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _C.textSec,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

enum _UploadSlotType { front, left, back, right }

class _StyleCard {
  const _StyleCard(this.name, this.icon, this.color, this.subtitle);

  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _TrendBadge {
  const _TrendBadge(this.label, this.color);

  final String label;
  final Color color;
}

class _HexGridPainter extends CustomPainter {
  const _HexGridPainter(this.opacity);

  final Animation<double> opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _C.electric.withOpacity(0.018 * opacity.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const double radius = 40.0;
    const double dx = radius * 1.732;
    const double dy = radius * 1.5;
    int row = 0;

    for (double y = -radius; y < size.height + radius; y += dy) {
      final double offset = row.isEven ? 0.0 : dx / 2;
      for (double x = -radius + offset; x < size.width + radius; x += dx) {
        final Path path = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = (math.pi / 180) * (60 * i - 30);
          final Offset point = Offset(
            x + radius * math.cos(angle),
            y + radius * math.sin(angle),
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _HexGridPainter oldDelegate) {
    return oldDelegate.opacity.value != opacity.value;
  }
}

class _C {
  static const Color obsidian = Color(0xFF080C12);
  static const Color deepNavy = Color(0xFF0D1420);
  static const Color surface = Color(0xFF111827);
  static const Color cardBorder = Color(0xFF1E2D45);
  static const Color electric = Color(0xFF00A8FF);
  static const Color textPrim = Color(0xFFEDF2F8);
  static const Color textSec = Color(0xFF7A90A8);
  static const Color purple = Color(0xFF8B5CF6);
}