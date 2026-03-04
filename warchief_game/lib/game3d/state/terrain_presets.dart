/// Terrain generation presets for the Scenario configuration.
///
/// Each preset defines the noise parameters passed to [InfiniteTerrainManager].
/// Values are tuned to produce distinctive visual profiles while keeping
/// the terrain traversable at game scale.
class TerrainPreset {
  final String id;
  final String name;
  final String description;

  /// Relative roughness label shown in the UI selector.
  final String roughnessLabel;

  // ==================== NOISE PARAMETERS ====================

  /// Maximum elevation above the base plane (world units).
  final double maxHeight;

  /// Noise feature frequency — lower = broader hills, higher = more jagged.
  final double noiseScale;

  /// Number of fractal octaves — more = finer surface detail.
  final int noiseOctaves;

  /// Octave amplitude falloff — higher = each octave contributes more.
  final double noisePersistence;

  const TerrainPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.roughnessLabel,
    required this.maxHeight,
    required this.noiseScale,
    required this.noiseOctaves,
    required this.noisePersistence,
  });

  /// Normalized height (0–1) relative to the tallest preset, for UI bars.
  double get normalizedHeight => maxHeight / 12.0;
}

/// All available terrain presets, ordered from smoothest to roughest.
const List<TerrainPreset> kTerrainPresets = [
  TerrainPreset(
    id: 'flat',
    name: 'Flat Plains',
    description: 'Nearly level ground with only the faintest undulation.',
    roughnessLabel: 'Smooth',
    maxHeight: 0.3,
    noiseScale: 0.01,
    noiseOctaves: 1,
    noisePersistence: 0.3,
  ),
  TerrainPreset(
    id: 'ancient_plains',
    name: 'Ancient Plains',
    description: 'Worn-down landscape with gentle, sweeping rises.',
    roughnessLabel: 'Gentle',
    maxHeight: 1.5,
    noiseScale: 0.015,
    noiseOctaves: 2,
    noisePersistence: 0.55,
  ),
  TerrainPreset(
    id: 'rolling_hills',
    name: 'Rolling Hills',
    description: 'Soft hills and shallow valleys — the default landscape.',
    roughnessLabel: 'Moderate',
    maxHeight: 3.0,
    noiseScale: 0.03,
    noiseOctaves: 2,
    noisePersistence: 0.5,
  ),
  TerrainPreset(
    id: 'desert_dunes',
    name: 'Desert Dunes',
    description: 'Broad, sculpted dunes with smooth crests and steep faces.',
    roughnessLabel: 'Moderate',
    maxHeight: 4.0,
    noiseScale: 0.07,
    noiseOctaves: 2,
    noisePersistence: 0.40,
  ),
  TerrainPreset(
    id: 'highlands',
    name: 'Highlands',
    description: 'High, open plateau country with significant elevation change.',
    roughnessLabel: 'Rough',
    maxHeight: 6.0,
    noiseScale: 0.025,
    noiseOctaves: 3,
    noisePersistence: 0.60,
  ),
  TerrainPreset(
    id: 'craggy_wastes',
    name: 'Craggy Wastes',
    description: 'Fractured, broken land with sharp ridges and sudden drops.',
    roughnessLabel: 'Very Rough',
    maxHeight: 8.0,
    noiseScale: 0.055,
    noiseOctaves: 4,
    noisePersistence: 0.65,
  ),
  TerrainPreset(
    id: 'mountains',
    name: 'Mountains',
    description: 'Dramatic peaks, deep ravines, and treacherous slopes.',
    roughnessLabel: 'Extreme',
    maxHeight: 12.0,
    noiseScale: 0.02,
    noiseOctaves: 4,
    noisePersistence: 0.70,
  ),
];

/// Look up a preset by [id], falling back to 'rolling_hills' if not found.
TerrainPreset getTerrainPreset(String id) {
  for (final p in kTerrainPresets) {
    if (p.id == id) return p;
  }
  return kTerrainPresets.firstWhere((p) => p.id == 'rolling_hills',
      orElse: () => kTerrainPresets[2]);
}
