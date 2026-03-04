import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../services/api_service.dart';

class IslandScreen extends StatefulWidget {
  const IslandScreen({super.key});

  @override
  State<IslandScreen> createState() => _IslandScreenState();
}

class _IslandScreenState extends State<IslandScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _islandData;
  final TransformationController _transformationController = TransformationController();

  late AnimationController _pulseController;
  late AnimationController _cloudController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _cloudController = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _waveController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _loadIslandState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cloudController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadIslandState() async {
    try {
      final data = await _apiService.getIslandState();
      if (mounted) {
        setState(() {
          _islandData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading island: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Isometric block builder ─────────────────────────────────────────────
  Widget _buildIsometricBlock(
      Color topColor, Color rightColor, Color leftColor, Widget child, {double height = 16.0}) {
    return Stack(
      children: [
        // Right face with gradient for depth
        Positioned(
          top: height,
          right: -height,
          bottom: -height,
          left: height,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.skewY(-0.5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [rightColor, rightColor.withValues(alpha: 0.8)],
                ),
              ),
            ),
          ),
        ),
        // Left face with gradient for depth
        Positioned(
          top: height,
          bottom: -height,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.only(top: height),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [leftColor, leftColor.withValues(alpha: 0.8)],
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: height, color: leftColor),
            ),
          ),
        ),
        // Top face with rich gradient and inner glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topColor, topColor.withValues(alpha: 0.9)],
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: const Offset(-2, -2),
                )
              ],
            ),
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(math.pi / 4)
                  ..rotateX(-math.pi / 3),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(String type, int index) {
    String emoji = '';
    Color topColor = const Color(0xFF66BB6A);
    Color rightColor = const Color(0xFF2E7D32);
    Color leftColor = const Color(0xFF388E3C);

    switch (type) {
      case 'grass':
        topColor = const Color(0xFF81C784);
        rightColor = const Color(0xFF388E3C);
        leftColor = const Color(0xFF43A047);
        break;
      case 'house':
        emoji = '🏠';
        topColor = const Color(0xFFFFD54F);
        rightColor = const Color(0xFFF57F17);
        leftColor = const Color(0xFFFBC02D);
        break;
      case 'tree':
        emoji = '🌴';
        topColor = const Color(0xFF43A047);
        rightColor = const Color(0xFF1B5E20);
        leftColor = const Color(0xFF2E7D32);
        break;
      case 'flower':
        emoji = '🌸';
        topColor = const Color(0xFFCE93D8);
        rightColor = const Color(0xFF7B1FA2);
        leftColor = const Color(0xFF8E24AA);
        break;
      case 'decay':
        emoji = '🍂';
        topColor = const Color(0xFFBCAAA4);
        rightColor = const Color(0xFF4E342E);
        leftColor = const Color(0xFF6D4C41);
        break;
      case 'locked':
        topColor = Colors.white.withValues(alpha: 0.05);
        rightColor = Colors.transparent;
        leftColor = Colors.transparent;
        break;
    }

    double blockHeight = 16.0;
    if (type == 'house') blockHeight = 22.0;
    if (type == 'tree') blockHeight = 20.0;
    if (type == 'locked') blockHeight = 8.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final double pulseY =
            (type == 'locked' || emoji.isEmpty) ? 0.0 : (_pulseController.value * 4.0);

        return _buildIsometricBlock(
          topColor,
          rightColor,
          leftColor,
          Padding(
            padding: EdgeInsets.only(bottom: pulseY),
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 28,
                shadows: [
                  Shadow(
                      blurRadius: 12.0,
                      color: Colors.black38,
                      offset: Offset(2, 4))
                ],
              ),
            ),
          ),
          height: blockHeight,
        )
            .animate()
            .scale(
                delay: Duration(milliseconds: 40 * index),
                duration: 500.ms,
                curve: Curves.easeOutBack)
            .slideY(
                begin: -0.8,
                end: 0,
                delay: Duration(milliseconds: 40 * index),
                duration: 500.ms,
                curve: Curves.bounceOut);
      },
    );
  }

  Widget _buildIsland() {
    final data = _islandData ?? {
      'trees': 2,
      'houses': 3,
      'unlockedAreas': 0,
      'decayLevel': 0,
    };

    final int trees = data['trees'] ?? 0;
    final int houses = data['houses'] ?? 0;
    final int unlockedAreas = data['unlockedAreas'] ?? 0;
    final int decayLevel = data['decayLevel'] ?? 0;

    final int totalTiles = 16 + (unlockedAreas * 4);
    List<String> tiles = List.filled(totalTiles, 'grass');

    for (int i = 0; i < decayLevel && i < tiles.length; i++) {
      tiles[i] = 'decay';
    }
    int houseCount = 0;
    for (int i = 0; i < tiles.length && houseCount < houses; i++) {
      if (tiles[i] == 'grass') {
        tiles[i] = 'house';
        houseCount++;
      }
    }
    int treeCount = 0;
    for (int i = 0; i < tiles.length && treeCount < trees; i++) {
      if (tiles[i] == 'grass') {
        tiles[i] = 'tree';
        treeCount++;
      }
    }

    final int crossAxisCount = totalTiles > 40
        ? 6
        : totalTiles > 24
            ? 5
            : 4;

    final double islandSize = crossAxisCount * 80.0;
    // Calculate precise grid height to prevent infinite/zero bounds
    final int rows = (totalTiles / crossAxisCount).ceil();
    final double gridHeight = rows * 80.0;

    return Positioned.fill(
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: EdgeInsets.all(islandSize * 2), // Generous boundaries
        minScale: 0.1,
        maxScale: 3.0,
        constrained: false, // Don't constrain child to viewport
        child: Align(
          alignment: Alignment.center,
          child: Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(0.9)
              ..rotateZ(-0.6),
            child: SizedBox(
              width: islandSize,
              height: gridHeight, // Explicit height based on rows
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Deep rocky base layer 2 - extra chunky
                  Positioned(
                    top: 60,
                    left: 60,
                    right: -60,
                    bottom: -60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1B18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  // Earthy crust layer 1
                  Positioned(
                    top: 30,
                    left: 30,
                    right: -30,
                    bottom: -30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E342E),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 150,
                            spreadRadius: 40,
                            offset: const Offset(80, 160),
                          )
                        ],
                      ),
                    ),
                  ),
                  // The Grid itself
                  Positioned.fill(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: totalTiles,
                      itemBuilder: (_, index) => _buildTile(tiles[index], index),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sky & environment painters ──────────────────────────────────────────
  Widget _buildSky() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF011627), // Deep space blue
              Color(0xFF0D47A1), // Midnight blue
              Color(0xFF1976D2), // Ocean surface blue
              Color(0xFF42A5F5), // Horizon blue
              Color(0xFFB3E5FC), // Light horizon
            ],
            stops: [0.0, 0.3, 0.6, 0.85, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildSun() {
    return Positioned(
      top: -50,
      right: -50,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          final scale = 1.0 + _pulseController.value * 0.05;
          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sun rays
                CustomPaint(
                  size: const Size(300, 300),
                  painter: _SunRayPainter(_pulseController.value),
                ),
                // Sun core
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFF9C4).withValues(alpha: 0.9),
                        const Color(0xFFFFF176).withValues(alpha: 0.5),
                        const Color(0xFFFFD54F).withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.1, 0.3, 0.6, 1.0],
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloud(double top, double animOffset, double width, double opacity) {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (_, __) {
        final x = (MediaQuery.of(context).size.width + 200) *
                _cloudController.value -
            100 +
            animOffset;
        return Positioned(
          top: top,
          left: x % (MediaQuery.of(context).size.width + 300) - 150,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: width,
              height: width * 0.8,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Fluffy cloud circles
                  _buildCloudPart(width * 0.5, 0, 0),
                  _buildCloudPart(width * 0.4, -width * 0.2, width * 0.1),
                  _buildCloudPart(width * 0.45, width * 0.25, width * 0.05),
                  _buildCloudPart(width * 0.35, width * 0.5, width * 0.15),
                ],
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .moveY(begin: 0, end: 10, duration: 4.seconds, curve: Curves.easeInOut),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloudPart(double size, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOcean() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (_, __) {
          final wave = _waveController.value;
          return Container(
            height: MediaQuery.of(context).size.height * 0.28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF29B6F6).withValues(alpha: 0.0),
                  const Color(0xFF0288D1).withValues(alpha: 0.6 + wave * 0.1),
                  const Color(0xFF01579B).withValues(alpha: 0.9),
                  const Color(0xFF003F72),
                ],
              ),
            ),
            child: CustomPaint(
              painter: _WavePainter(wave),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsPanel() {
    final data = _islandData ?? {
      'trees': 2,
      'houses': 3,
      'unlockedAreas': 0,
      'decayLevel': 0,
    };
    final trees = data['trees'] ?? 0;
    final houses = data['houses'] ?? 0;
    final decay = data['decayLevel'] ?? 0;
    final unlocked = data['unlockedAreas'] ?? 0;

    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatChip('🌴', '$trees', 'Trees'),
                _buildVerticalDivider(),
                _buildStatChip('🏠', '$houses', 'Houses'),
                _buildVerticalDivider(),
                _buildStatChip('🗺️', '$unlocked', 'Areas'),
                _buildVerticalDivider(),
                _buildStatChip('🍂', '$decay', 'Decay'),
              ],
            ),
          ),
        ),
      ).animate().fade(duration: 800.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildStatChip(String emoji, String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomHint() {
    return Positioned(
      bottom: 140, // Increased to definitely clear the stats bar
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Text(
            '🏆 Complete habits to grow your island',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              shadows: [
                const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .fade(duration: 1.seconds)
         .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Habit Island 🌴',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              const Shadow(
                  blurRadius: 10, color: Colors.black38, offset: Offset(0, 2))
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D47A1), Color(0xFF01579B)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : Stack(
              children: [
                _buildSky(),
                _buildSun(),
                // Multiple cloud layers for parallax-like effect
                _buildCloud(80, 0, 150, 0.4),
                _buildCloud(140, 400, 100, 0.3),
                _buildCloud(200, 150, 180, 0.2),
                _buildCloud(40, 800, 120, 0.5),
                _buildFloatingParticles(),
                _buildOcean(),

                // Island grid in center
                Positioned.fill(
                  child: _buildIsland(),
                ),

                // Stats panel at the bottom
                _buildStatsPanel(),

                _buildBottomHint(),
              ],
            ),
    );
  }
}

// ── Wave effect painter ────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double phase;
  _WavePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (int w = 0; w < 3; w++) {
      final path = Path();
      final offset = phase * size.width * 0.3 + w * 60.0;
      path.moveTo(0, size.height * 0.3);
      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.25 +
            math.sin((x / size.width * 2 * math.pi) + offset / 50) *
                (8.0 - w * 2);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}

Widget _buildFloatingParticles() {
  return Positioned.fill(
    child: IgnorePointer(
      child: Stack(
        children: List.generate(15, (i) {
          final random = math.Random(i);
          return _FloatingParticle(
            delay: i * 200,
            x: random.nextDouble(),
            y: random.nextDouble(),
          );
        }),
      ),
    ),
  );
}

class _FloatingParticle extends StatelessWidget {
  final int delay;
  final double x;
  final double y;

  const _FloatingParticle({required this.delay, required this.x, required this.y});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x * MediaQuery.of(context).size.width,
      top: y * MediaQuery.of(context).size.height,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .fade(duration: 2.seconds, delay: delay.ms)
          .moveY(begin: 0, end: -40, duration: 3.seconds, curve: Curves.easeInOut)
          .scale(begin: const Offset(1, 1), end: const Offset(0.5, 0.5)),
    );
  }
}

class _SunRayPainter extends CustomPainter {
  final double pulse;
  _SunRayPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF176).withValues(alpha: 0.2 + pulse * 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 + pulse * 10) * math.pi / 180;
      final path = Path();
      const rayWidth = 0.15;
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + math.cos(angle - rayWidth) * size.width / 2,
        center.dy + math.sin(angle - rayWidth) * size.height / 2,
      );
      path.lineTo(
        center.dx + math.cos(angle + rayWidth) * size.width / 2,
        center.dy + math.sin(angle + rayWidth) * size.height / 2,
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunRayPainter old) => old.pulse != pulse;
}
