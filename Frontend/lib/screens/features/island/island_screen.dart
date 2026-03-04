import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  Widget _buildTile(String type, int index) {
    String emoji = '🌱';
    Color bgColor = const Color(0xFFC8E6C9); // Grass
    Color borderColor = const Color(0xFFA5D6A7);

    if (type == 'house') {
      emoji = '🏠';
      bgColor = const Color(0xFFFFCCBC); // Warm Base
      borderColor = const Color(0xFFFFAB91);
    } else if (type == 'tree') {
      emoji = '🌴';
      bgColor = const Color(0xFF81C784); // Deeper Green
      borderColor = const Color(0xFF66BB6A);
    } else if (type == 'decay') {
      emoji = '🍂';
      bgColor = const Color(0xFFD7CCC8); // Withered Grey
      borderColor = const Color(0xFFBCAAA4);
    } else if (type == 'locked') {
      emoji = '☁️';
      bgColor = Colors.white.withOpacity(0.1);
      borderColor = Colors.white.withOpacity(0.2);
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulse = type == 'locked' ? 0.0 : (_pulseController.value * 2.0);
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: type == 'locked' ? [] : [
              BoxShadow(
                color: borderColor.withOpacity(0.5),
                blurRadius: 10 + pulse,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ).animate(target: type == 'locked' ? 0 : 1).moveY(begin: 5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
          ),
        ).animate().scale(delay: Duration(milliseconds: 50 * index), duration: 400.ms, curve: Curves.easeOutBack);
      }
    );
  }

  Widget _buildIslandGrid() {
    if (_islandData == null) return const SizedBox.shrink();

    final int trees = _islandData!['trees'] ?? 0;
    final int houses = _islandData!['houses'] ?? 0;
    final int unlockedAreas = _islandData!['unlockedAreas'] ?? 0;
    final int decayLevel = _islandData!['decayLevel'] ?? 0;

    // Base island size is 16 tiles (4x4). Unlock areas expands it.
    final int totalTiles = 16 + (unlockedAreas * 4);
    
    // Create a list of tile types
    List<String> tiles = List.filled(totalTiles, 'grass');
    
    // Populate Decayed Tiles
    for (int i = 0; i < decayLevel && i < tiles.length; i++) {
      tiles[i] = 'decay';
    }
    
    // Populate Houses
    int houseCount = 0;
    for (int i = 0; i < tiles.length && houseCount < houses; i++) {
        if (tiles[i] == 'grass') {
            tiles[i] = 'house';
            houseCount++;
        }
    }
    
    // Populate Trees
    int treeCount = 0;
    for (int i = 0; i < tiles.length && treeCount < trees; i++) {
        if (tiles[i] == 'grass') {
            tiles[i] = 'tree';
            treeCount++;
        }
    }

    // Determine grid cross axis count
    int crossAxisCount = 4;
    if (totalTiles > 24) crossAxisCount = 5;
    if (totalTiles > 40) crossAxisCount = 6;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.0,
      ),
      itemCount: totalTiles,
      itemBuilder: (context, index) {
        return _buildTile(tiles[index], index);
      },
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
          'My Island 🌴',
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
            // Ambient Ocean Background Effects
            Positioned(
              bottom: 0,
              left: -50,
              right: -50,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFB2EBF2).withOpacity(0.0),
                      const Color(0xFF4DD0E1).withOpacity(0.5),
                      const Color(0xFF00BCD4).withOpacity(0.8),
                    ]
                  )
                ),
              ),
            ),
            
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Island Stats Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00838F).withOpacity(0.1),
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
                  
                  const SizedBox(height: 40),
                  
                  // The Island Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4), // Sand border
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ]
                    ),
                    child: _buildIslandGrid(),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    'Complete habits to grow your island!\nBad habits will cause decay.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF006064).withOpacity(0.7),
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
            color: const Color(0xFF006064).withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
