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

class _IslandScreenState extends State<IslandScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _islandData;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadIslandState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
      debugPrint('Error loading island: \$e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper widget to build the "faces" of the 3D block
  Widget _buildIsometricBlock(Color topColor, Color rightColor, Color leftColor, Widget child) {
    const double blockHeight = 15.0; // The extrusion depth
    
    return Stack(
      children: [
        // Simulated Right Face
        Positioned(
          top: blockHeight,
          right: -blockHeight,
          bottom: -blockHeight,
          left: blockHeight,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.skewY(-0.5), // Skew to form the side
            child: Container(color: rightColor),
          ),
        ),
        
        // Simulated Left Face
        Positioned(
          top: blockHeight,
          bottom: -blockHeight,
          left: 0,
          right: 0,
          child: Container(
            color: leftColor,
            margin: const EdgeInsets.only(top: blockHeight), // offset down
            child: Align(alignment: Alignment.centerLeft, child: Container(width: blockHeight, color: leftColor)), // Hacky quick left depth
          ),
        ),

        // The Top Face (The actual tile surface)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: topColor,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Center(
              // Counter-rotate the children so they stand UP off the flat map
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(math.pi / 4) // counter Z rotate
                  ..rotateX(-math.pi / 3), // counter X tilt
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
    Color topColor = const Color(0xFF81C784);  // Grass Top
    Color rightColor = const Color(0xFF388E3C); // Darker Grass Shadow
    Color leftColor = const Color(0xFF4CAF50);  // Mid Grass Shadow

    if (type == 'house') {
      emoji = '🏠';
      topColor = const Color(0xFFFFCCBC);
      rightColor = const Color(0xFFD84315);
      leftColor = const Color(0xFFE64A19);
    } else if (type == 'tree') {
      emoji = '🌴';
    } else if (type == 'decay') {
      emoji = '🍂';
      topColor = const Color(0xFFD7CCC8);
      rightColor = const Color(0xFF5D4037);
      leftColor = const Color(0xFF795548);
    } else if (type == 'locked') {
      topColor = Colors.white.withValues(alpha: 0.1);
      rightColor = Colors.transparent;
      leftColor = Colors.transparent;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulseY = type == 'locked' || emoji.isEmpty ? 0.0 : (_pulseController.value * 5.0);
        
        // Build the extruded block
        Widget block = _buildIsometricBlock(
          topColor, 
          rightColor, 
          leftColor, 
          // The item on top
          Padding(
            padding: EdgeInsets.only(bottom: pulseY), // animate floating
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 32, shadows: [
                 Shadow(blurRadius: 10.0, color: Colors.black45, offset: Offset(2, 5)) // Ground shadow
              ]),
            ),
          ),
        );

        // Enter animation for the blocks themselves falling into place
        return block.animate()
               .scale(delay: Duration(milliseconds: 50 * index), duration: 600.ms, curve: Curves.easeOutBack)
               .slideY(begin: -1.0, end: 0, delay: Duration(milliseconds: 50 * index), duration: 600.ms, curve: Curves.bounceOut);
      }
    );
  }

  Widget _buildIsometricIslandGrid() {
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

    int crossAxisCount = 4;
    if (totalTiles > 24) crossAxisCount = 5;
    if (totalTiles > 40) crossAxisCount = 6;

    // Apply the Isometric Matrix Transform to the entire grid
    return Center(
      child: Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective depth
          ..rotateX(math.pi / 3)   // Tilt back 60 degrees
          ..rotateZ(-math.pi / 4), // Rotate 45 degrees
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withValues(alpha: 0.2),
                 blurRadius: 50,
                 spreadRadius: 10,
                 offset: const Offset(20, 50),
               )
            ]
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.0, 
              crossAxisSpacing: 0, // No spacing so blocks touch
              mainAxisSpacing: 0,
            ),
            itemCount: totalTiles,
            itemBuilder: (context, index) {
              return _buildTile(tiles[index], index);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Soft ocean blue sky
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF006064)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My 3D Island 🌴',
          style: GoogleFonts.poppins(
            color: const Color(0xFF006064),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00838F)))
        : Stack(
          children: [
            // Ambient Ocean Background
            Positioned(
              bottom: 0,
              left: -50,
              right: -50,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFB2EBF2).withValues(alpha: 0.0),
                      const Color(0xFF4DD0E1).withValues(alpha: 0.5),
                      const Color(0xFF00BCD4).withValues(alpha: 0.8),
                    ]
                  )
                ),
              ),
            ),
            
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Island Stats Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00838F).withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('🌴', _islandData?['trees']?.toString() ?? '0', 'Trees'),
                          _buildStat('🏠', _islandData?['houses']?.toString() ?? '0', 'Houses'),
                          _buildStat('🍂', _islandData?['decayLevel']?.toString() ?? '0', 'Decay'),
                        ],
                      ),
                    ).animate().fade(duration: 500.ms).slideY(begin: -0.2, end: 0),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // The 3D Island Render Zone
                  SizedBox(
                    height: 400, // Fixed height for the 3D projection to fit
                    child: _buildIsometricIslandGrid(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    'Complete habits to grow your island!\nBad habits will cause decay.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF006064).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fade(delay: 600.ms),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildStat(String emoji, String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00838F),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF006064).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

