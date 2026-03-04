import 'package:flutter/material.dart';
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
      Color topColor, Color rightColor, Color leftColor, Widget child) {
    const double blockHeight = 14.0;

    return Stack(
      children: [
        // Right face
        Positioned(
          top: blockHeight,
          right: -blockHeight,
          bottom: -blockHeight,
          left: blockHeight,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.skewY(-0.5),
            child: Container(color: rightColor),
          ),
        ),
        // Left face
        Positioned(
          top: blockHeight,
          bottom: -blockHeight,
          left: 0,
          right: 0,
          child: Container(
            color: leftColor,
            margin: const EdgeInsets.only(top: blockHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: blockHeight, color: leftColor),
            ),
          ),
        ),
        // Top face
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: topColor,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 0.5),
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
      case 'house':
        emoji = '🏠';
        topColor = const Color(0xFFFFCCBC);
        rightColor = const Color(0xFFBF360C);
        leftColor = const Color(0xFFD84315);
        break;
      case 'tree':
        emoji = '🌴';
        topColor = const Color(0xFF43A047);
        rightColor = const Color(0xFF1B5E20);
        leftColor = const Color(0xFF2E7D32);
        break;
      case 'flower':
        emoji = '🌸';
        topColor = const Color(0xFF81C784);
        rightColor = const Color(0xFF388E3C);
        leftColor = const Color(0xFF43A047);
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
    if (_islandData == null) return const SizedBox.shrink();

    final int trees = _islandData!['trees'] ?? 0;
    final int houses = _islandData!['houses'] ?? 0;
    final int unlockedAreas = _islandData!['unlockedAreas'] ?? 0;
    final int decayLevel = _islandData!['decayLevel'] ?? 0;

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

    return Center(
      child: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(math.pi / 3)
          ..rotateZ(-math.pi / 4),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 60,
                spreadRadius: 10,
                offset: const Offset(20, 60),
              )
            ],
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.0,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: totalTiles,
            itemBuilder: (_, index) => _buildTile(tiles[index], index),
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
              Color(0xFF0D47A1), // deep midnight blue
              Color(0xFF1565C0),
              Color(0xFF1976D2),
              Color(0xFF42A5F5), // horizon blue
              Color(0xFF80DEEA), // near water cyan
            ],
            stops: [0.0, 0.2, 0.45, 0.72, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildSun() {
    return Positioned(
      top: 60,
      right: 40,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          final glow = 0.3 + _pulseController.value * 0.2;
          return Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF176),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFF176).withValues(alpha: glow),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: glow * 0.5),
                  blurRadius: 100,
                  spreadRadius: 40,
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
        final x = (MediaQuery.of(context).size.width + 100) *
                _cloudController.value -
            50 +
            animOffset;
        return Positioned(
          top: top,
          left: x % (MediaQuery.of(context).size.width + 200) - 100,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: width,
              height: width * 0.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width),
                color: Colors.white.withValues(alpha: 0.85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                  )
                ],
              ),
            ),
          ),
        );
      },
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
    final trees = _islandData?['trees'] ?? 0;
    final houses = _islandData?['houses'] ?? 0;
    final decay = _islandData?['decayLevel'] ?? 0;
    final unlocked = _islandData?['unlockedAreas'] ?? 0;

    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
      ).animate().fade(duration: 600.ms).slideY(begin: -0.3, end: 0),
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
      bottom: MediaQuery.of(context).size.height * 0.28 + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🏆 Complete habits to grow your island',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ).animate().fade(delay: 800.ms),
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
                _buildCloud(80, 0, 120, 0.7),
                _buildCloud(110, 300, 80, 0.5),
                _buildCloud(50, 600, 100, 0.6),
                _buildOcean(),

                // Island grid in center
                Positioned(
                  top: kToolbarHeight + 80,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: _buildIsland(),
                ),

                // Stats panel just below the app bar
                Positioned(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 4,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatChip('🌴',
                            '${_islandData?['trees'] ?? 0}', 'Trees'),
                        _buildVerticalDivider(),
                        _buildStatChip('🏠',
                            '${_islandData?['houses'] ?? 0}', 'Houses'),
                        _buildVerticalDivider(),
                        _buildStatChip('🗺️',
                            '${_islandData?['unlockedAreas'] ?? 0}', 'Areas'),
                        _buildVerticalDivider(),
                        _buildStatChip('🍂',
                            '${_islandData?['decayLevel'] ?? 0}', 'Decay'),
                      ],
                    ),
                  ).animate().fade(duration: 600.ms).slideY(begin: -0.3, end: 0),
                ),

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
