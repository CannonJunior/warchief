// Terrain-specific shaders for WoW-style texture splatting
//
// Implements multi-texture terrain blending with:
// - 4 terrain texture layers (grass, dirt, rock, sand)
// - Splat map blending (RGBA channels control layer weights)
// - Normal mapping for surface detail
// - Height/slope-based automatic blending
// - Detail texture overlay for close-up variation
//
// Texture Unit Assignment:
// - 0-3: Diffuse textures (grass, dirt, rock, sand)
// - 4-7: Normal textures (grass, dirt, rock, sand)
// - 8: Detail texture
// - 9: Splat map

/// Terrain vertex shader
///
/// Transforms vertices and passes UV coordinates for texture sampling.
/// Calculates world position for lighting and detail blending.
const String terrainVertexShader = '''
// Vertex attributes
attribute vec3 aPosition;
attribute vec3 aNormal;
attribute vec2 aTexCoord;

// Transform matrices
uniform mat4 uProjection;
uniform mat4 uView;
uniform mat4 uModel;

// Terrain configuration
uniform float uTextureScale;  // How many times textures repeat per tile
uniform float uChunkSize;     // Size of terrain chunk in world units

// Outputs to fragment shader
varying vec3 vWorldPos;       // World position for lighting
varying vec3 vNormal;         // Surface normal
varying vec2 vTexCoord;       // Base UV for splat map sampling
varying vec2 vDetailCoord;    // Detail UV (higher frequency)
varying float vHeight;        // Height for auto-blending
varying float vSlope;         // Slope for auto-blending
varying float vCameraDistance; // Distance from camera for detail fading

void main() {
  // Transform to world space
  vec4 worldPos = uModel * vec4(aPosition, 1.0);
  vWorldPos = worldPos.xyz;

  // Transform normal to world space
  vNormal = normalize(mat3(uModel) * aNormal);

  // Calculate slope from normal (1.0 = flat, 0.0 = vertical)
  vSlope = vNormal.y;

  // Pass height for auto-blending
  vHeight = aPosition.y;

  // Base UV coordinates (0-1 across chunk, used for splat map)
  vTexCoord = aTexCoord;

  // Detail UV coordinates (tiled based on texture scale)
  vDetailCoord = aTexCoord * uTextureScale;

  // Calculate camera distance for detail fading
  vec4 viewPos = uView * worldPos;
  vCameraDistance = length(viewPos.xyz);

  // Final position
  gl_Position = uProjection * uView * worldPos;
}
''';

/// Terrain fragment shader with texture splatting
///
/// Blends 4 terrain textures based on splat map weights.
/// Includes normal mapping and detail texture overlay.
const String terrainFragmentShader = '''
precision mediump float;

// Terrain diffuse textures
uniform sampler2D uTexGrass;   // Texture unit 0
uniform sampler2D uTexDirt;    // Texture unit 1
uniform sampler2D uTexRock;    // Texture unit 2
uniform sampler2D uTexSand;    // Texture unit 3

// Terrain normal textures
uniform sampler2D uNormGrass;  // Texture unit 4
uniform sampler2D uNormDirt;   // Texture unit 5
uniform sampler2D uNormRock;   // Texture unit 6
uniform sampler2D uNormSand;   // Texture unit 7

// Additional textures
uniform sampler2D uDetail;     // Texture unit 8 - high frequency detail
uniform sampler2D uSplatMap;   // Texture unit 9 - terrain blend weights

// Lighting
uniform vec3 uLightPos;
uniform vec3 uLightColor;
uniform vec3 uAmbientColor;
uniform vec3 uCameraPos;

// Configuration
uniform float uDetailDistance;  // Distance at which detail fades out
uniform float uMaxHeight;       // Maximum terrain height for normalization
// Note: Boolean uniforms removed - using simplified shader without conditional features

// Height thresholds for auto-blending (when splat map not used)
uniform float uSandMaxHeight;   // Below this = sand
uniform float uGrassMaxHeight;  // Above this starts rock blend
uniform float uRockMinSlope;    // Slope below this = rock

// Inputs from vertex shader
varying vec3 vWorldPos;
varying vec3 vNormal;
varying vec2 vTexCoord;
varying vec2 vDetailCoord;
varying float vHeight;
varying float vSlope;
varying float vCameraDistance;

// Unpack normal from normal map
vec3 unpackNormal(vec4 normalSample) {
  vec3 normal = normalSample.rgb * 2.0 - 1.0;
  return normalize(normal);
}

// Calculate splat weights from height and slope (auto-blend mode)
vec4 calculateAutoSplat() {
  float normalizedHeight = vHeight / uMaxHeight;

  // Initialize weights
  float grass = 0.0;
  float dirt = 0.0;
  float rock = 0.0;
  float sand = 0.0;

  // Height-based distribution
  if (normalizedHeight < uSandMaxHeight) {
    // Low areas: sand with grass transition
    sand = 1.0 - smoothstep(0.0, uSandMaxHeight, normalizedHeight);
    grass = smoothstep(0.0, uSandMaxHeight, normalizedHeight);
  } else if (normalizedHeight < uGrassMaxHeight) {
    // Mid areas: grass with dirt spots
    grass = 1.0;
    // Add some dirt variation using position
    float dirtNoise = fract(sin(dot(vWorldPos.xz, vec2(12.9898, 78.233))) * 43758.5453);
    if (dirtNoise > 0.85) {
      dirt = 0.4;
      grass = 0.6;
    }
  } else {
    // High areas: rock with grass transition
    rock = smoothstep(uGrassMaxHeight, 1.0, normalizedHeight);
    grass = 1.0 - rock;
  }

  // Slope-based rock override
  // Steep slopes (low vSlope value = steep)
  if (vSlope < uRockMinSlope) {
    float slopeRockFactor = 1.0 - smoothstep(0.0, uRockMinSlope, vSlope);
    rock = max(rock, slopeRockFactor);
    grass *= (1.0 - slopeRockFactor);
    sand *= (1.0 - slopeRockFactor);
    dirt *= (1.0 - slopeRockFactor);
  }

  // Normalize weights to sum to 1.0
  vec4 weights = vec4(grass, dirt, rock, sand);
  float total = weights.r + weights.g + weights.b + weights.a;
  if (total > 0.0) {
    weights /= total;
  } else {
    weights = vec4(1.0, 0.0, 0.0, 0.0); // Default to grass
  }

  return weights;
}

void main() {
  // Get splat weights using height/slope-based auto-blend
  vec4 splat = calculateAutoSplat();

  // Normalize splat weights (ensure they sum to 1)
  float totalWeight = splat.r + splat.g + splat.b + splat.a;
  if (totalWeight > 0.0) {
    splat /= totalWeight;
  }

  // Sample diffuse textures - use vDetailCoord for tiling
  vec4 grassColor = texture2D(uTexGrass, vDetailCoord);
  vec4 dirtColor = texture2D(uTexDirt, vDetailCoord);
  vec4 rockColor = texture2D(uTexRock, vDetailCoord);
  vec4 sandColor = texture2D(uTexSand, vDetailCoord);

  // DEBUG: Check if textures are sampling correctly
  // Uncomment to see if grass texture is being sampled:
  // gl_FragColor = grassColor;
  // return;

  // Blend diffuse colors based on splat weights
  vec4 baseColor = grassColor * splat.r +
                   dirtColor * splat.g +
                   rockColor * splat.b +
                   sandColor * splat.a;

  // Calculate surface normal with optional normal mapping
  vec3 surfaceNormal = normalize(vNormal);

  // Normal mapping - blend normals from terrain textures
  vec3 grassNorm = unpackNormal(texture2D(uNormGrass, vDetailCoord));
  vec3 dirtNorm = unpackNormal(texture2D(uNormDirt, vDetailCoord));
  vec3 rockNorm = unpackNormal(texture2D(uNormRock, vDetailCoord));
  vec3 sandNorm = unpackNormal(texture2D(uNormSand, vDetailCoord));

  vec3 blendedNormal = grassNorm * splat.r +
                       dirtNorm * splat.g +
                       rockNorm * splat.b +
                       sandNorm * splat.a;

  // Combine with geometric normal (simple approach for mostly flat terrain)
  surfaceNormal = normalize(vNormal + blendedNormal * 0.3);

  // Apply detail texture for close-up variation
  float detailFade = 1.0 - smoothstep(0.0, uDetailDistance, vCameraDistance);
  if (detailFade > 0.01) {
    vec4 detailSample = texture2D(uDetail, vDetailCoord * 4.0);
    float detailValue = (detailSample.r - 0.5) * 2.0 * detailFade * 0.15;
    baseColor.rgb += detailValue;
  }

  // Lighting calculation
  vec3 lightDir = normalize(uLightPos - vWorldPos);

  // Diffuse lighting
  float diff = max(dot(surfaceNormal, lightDir), 0.0);
  vec3 diffuse = diff * uLightColor;

  // Ambient lighting
  vec3 ambient = uAmbientColor;

  // Final color
  vec3 finalColor = (ambient + diffuse) * baseColor.rgb;

  gl_FragColor = vec4(finalColor, 1.0);
}
''';

/// Simplified terrain shader (no normal mapping, for better performance)
///
/// Use this for lower LOD levels or low-end devices.
const String terrainFragmentShaderSimple = '''
precision mediump float;

// Terrain diffuse textures
uniform sampler2D uTexGrass;   // Texture unit 0
uniform sampler2D uTexDirt;    // Texture unit 1
uniform sampler2D uTexRock;    // Texture unit 2
uniform sampler2D uTexSand;    // Texture unit 3

// Splat map
uniform sampler2D uSplatMap;   // Texture unit 9

// Lighting
uniform vec3 uLightPos;
uniform vec3 uLightColor;
uniform vec3 uAmbientColor;

// Configuration
uniform float uMaxHeight;
uniform bool uUseSplatMap;
uniform float uSandMaxHeight;
uniform float uGrassMaxHeight;
uniform float uRockMinSlope;

// Inputs from vertex shader
varying vec3 vWorldPos;
varying vec3 vNormal;
varying vec2 vTexCoord;
varying vec2 vDetailCoord;
varying float vHeight;
varying float vSlope;

// Auto-blend calculation (same as full shader)
vec4 calculateAutoSplat() {
  float normalizedHeight = vHeight / uMaxHeight;

  float grass = 0.0;
  float dirt = 0.0;
  float rock = 0.0;
  float sand = 0.0;

  if (normalizedHeight < uSandMaxHeight) {
    sand = 1.0 - smoothstep(0.0, uSandMaxHeight, normalizedHeight);
    grass = smoothstep(0.0, uSandMaxHeight, normalizedHeight);
  } else if (normalizedHeight < uGrassMaxHeight) {
    grass = 1.0;
  } else {
    rock = smoothstep(uGrassMaxHeight, 1.0, normalizedHeight);
    grass = 1.0 - rock;
  }

  if (vSlope < uRockMinSlope) {
    float slopeRockFactor = 1.0 - smoothstep(0.0, uRockMinSlope, vSlope);
    rock = max(rock, slopeRockFactor);
    grass *= (1.0 - slopeRockFactor);
    sand *= (1.0 - slopeRockFactor);
  }

  vec4 weights = vec4(grass, dirt, rock, sand);
  float total = weights.r + weights.g + weights.b + weights.a;
  if (total > 0.0) {
    weights /= total;
  } else {
    weights = vec4(1.0, 0.0, 0.0, 0.0);
  }

  return weights;
}

void main() {
  // Get splat weights
  vec4 splat;
  if (uUseSplatMap) {
    splat = texture2D(uSplatMap, vTexCoord);
  } else {
    splat = calculateAutoSplat();
  }

  // Normalize
  float totalWeight = splat.r + splat.g + splat.b + splat.a;
  if (totalWeight > 0.0) {
    splat /= totalWeight;
  }

  // Sample and blend diffuse textures
  vec4 baseColor = texture2D(uTexGrass, vDetailCoord) * splat.r +
                   texture2D(uTexDirt, vDetailCoord) * splat.g +
                   texture2D(uTexRock, vDetailCoord) * splat.b +
                   texture2D(uTexSand, vDetailCoord) * splat.a;

  // Simple lighting
  vec3 lightDir = normalize(uLightPos - vWorldPos);
  float diff = max(dot(normalize(vNormal), lightDir), 0.0);
  vec3 lighting = uAmbientColor + diff * uLightColor;

  gl_FragColor = vec4(lighting * baseColor.rgb, 1.0);
}
''';

/// Debug shader for visualizing splat weights
///
/// Shows RGBA splat channels as colors for debugging terrain distribution.
const String terrainDebugFragmentShader = '''
precision mediump float;

uniform sampler2D uSplatMap;
uniform float uMaxHeight;
uniform bool uUseSplatMap;
uniform float uSandMaxHeight;
uniform float uGrassMaxHeight;
uniform float uRockMinSlope;

varying vec2 vTexCoord;
varying float vHeight;
varying float vSlope;

vec4 calculateAutoSplat() {
  float normalizedHeight = vHeight / uMaxHeight;

  float grass = 0.0;
  float rock = 0.0;
  float sand = 0.0;

  if (normalizedHeight < uSandMaxHeight) {
    sand = 1.0 - smoothstep(0.0, uSandMaxHeight, normalizedHeight);
    grass = smoothstep(0.0, uSandMaxHeight, normalizedHeight);
  } else if (normalizedHeight < uGrassMaxHeight) {
    grass = 1.0;
  } else {
    rock = smoothstep(uGrassMaxHeight, 1.0, normalizedHeight);
    grass = 1.0 - rock;
  }

  if (vSlope < uRockMinSlope) {
    float slopeRockFactor = 1.0 - smoothstep(0.0, uRockMinSlope, vSlope);
    rock = max(rock, slopeRockFactor);
    grass *= (1.0 - slopeRockFactor);
    sand *= (1.0 - slopeRockFactor);
  }

  vec4 weights = vec4(grass, 0.0, rock, sand);
  float total = weights.r + weights.g + weights.b + weights.a;
  if (total > 0.0) weights /= total;

  return weights;
}

void main() {
  vec4 splat;
  if (uUseSplatMap) {
    splat = texture2D(uSplatMap, vTexCoord);
  } else {
    splat = calculateAutoSplat();
  }

  // Visualize: R=grass(green), G=dirt(brown), B=rock(gray), A=sand(yellow)
  vec3 grassVis = vec3(0.2, 0.8, 0.2) * splat.r;
  vec3 dirtVis = vec3(0.6, 0.4, 0.2) * splat.g;
  vec3 rockVis = vec3(0.5, 0.5, 0.5) * splat.b;
  vec3 sandVis = vec3(0.9, 0.85, 0.5) * splat.a;

  gl_FragColor = vec4(grassVis + dirtVis + rockVis + sandVis, 1.0);
}
''';

/// Terrain shader uniform names (for easy reference)
class TerrainShaderUniforms {
  // Matrices
  static const String projection = 'uProjection';
  static const String view = 'uView';
  static const String model = 'uModel';

  // Diffuse textures
  static const String texGrass = 'uTexGrass';
  static const String texDirt = 'uTexDirt';
  static const String texRock = 'uTexRock';
  static const String texSand = 'uTexSand';

  // Normal textures
  static const String normGrass = 'uNormGrass';
  static const String normDirt = 'uNormDirt';
  static const String normRock = 'uNormRock';
  static const String normSand = 'uNormSand';

  // Additional textures
  static const String detail = 'uDetail';
  static const String splatMap = 'uSplatMap';

  // Lighting
  static const String lightPos = 'uLightPos';
  static const String lightColor = 'uLightColor';
  static const String ambientColor = 'uAmbientColor';
  static const String cameraPos = 'uCameraPos';

  // Configuration
  static const String textureScale = 'uTextureScale';
  static const String chunkSize = 'uChunkSize';
  static const String detailDistance = 'uDetailDistance';
  static const String maxHeight = 'uMaxHeight';
  static const String useNormalMaps = 'uUseNormalMaps';
  static const String useDetailMap = 'uUseDetailMap';
  static const String useSplatMap = 'uUseSplatMap';

  // Height/slope thresholds
  static const String sandMaxHeight = 'uSandMaxHeight';
  static const String grassMaxHeight = 'uGrassMaxHeight';
  static const String rockMinSlope = 'uRockMinSlope';
}

/// Terrain shader attribute names
class TerrainShaderAttributes {
  static const String position = 'aPosition';
  static const String normal = 'aNormal';
  static const String texCoord = 'aTexCoord';
}
