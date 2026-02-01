import 'dart:html' as html;
import 'package:vector_math/vector_math.dart';
import 'camera3d.dart';
import 'mesh.dart';
import 'math/transform3d.dart';
import 'shader_program.dart';
import 'texture_manager.dart';
import 'terrain_lod.dart';
import 'shaders/terrain_shaders.dart';
import 'game_config_terrain.dart';

/// WebGLRenderer - Core 3D rendering engine using WebGL
///
/// Manages WebGL context, shader programs, buffers, and rendering pipeline.
/// This replaces Flame's 2D rendering for true 3D with dual-axis rotation.
/// Supports texture splatting for terrain rendering.
///
/// Usage:
/// ```dart
/// final canvas = html.CanvasElement(width: 800, height: 600);
/// final renderer = WebGLRenderer(canvas);
/// renderer.clear();
/// renderer.render(mesh, transform, camera);
/// // For terrain:
/// renderer.renderTerrain(chunk, transform, camera);
/// ```
class WebGLRenderer {
  final html.CanvasElement canvas;
  final dynamic gl; // WebGL RenderingContext (typed as dynamic for compatibility)

  /// Default shader program (for non-terrain objects)
  late ShaderProgram shader;

  /// Terrain shader program (with texture splatting)
  ShaderProgram? _terrainShader;

  /// Texture manager for terrain textures
  TextureManager? _textureManager;

  /// Whether terrain texturing is enabled
  bool _terrainTexturingEnabled = false;

  /// Debug flag to avoid spamming logs
  bool _loggedMissingTexCoords = false;

  /// Lighting parameters
  Vector3 lightPosition = Vector3(10, 20, 10);
  Vector3 lightColor = Vector3(1.0, 1.0, 1.0);
  Vector3 ambientColor = Vector3(0.3, 0.3, 0.3);

  /// Cached buffers for meshes (to avoid recreating them every frame)
  final Map<Mesh, _MeshBuffers> _meshBuffers = {};

  WebGLRenderer._(this.canvas, this.gl) {
    _initialize();
  }

  /// Create a WebGLRenderer from a canvas element
  factory WebGLRenderer(html.CanvasElement canvas) {
    final gl = canvas.getContext3d(
      alpha: false,
      depth: true,
      antialias: true,
    );

    if (gl == null) {
      throw Exception('WebGL not supported');
    }

    return WebGLRenderer._(canvas, gl);
  }

  /// Initialize WebGL state
  void _initialize() {
    // Enable depth testing (so closer objects appear in front)
    gl.enable(0x0B71); // DEPTH_TEST
    gl.depthFunc(0x0201); // LESS

    // Enable backface culling (don't draw triangle backs)
    gl.enable(0x0B44); // CULL_FACE
    gl.cullFace(0x0405); // BACK

    // Set clear color (dark gray background)
    gl.clearColor(0.1, 0.1, 0.1, 1.0);

    // Create default shader
    shader = ShaderProgram.fromSource(gl, defaultVertexShader, defaultFragmentShader);

    print('WebGLRenderer initialized');
  }

  /// Initialize terrain texturing system
  ///
  /// Call this once during game initialization to enable textured terrain.
  /// This loads all terrain textures and creates the terrain shader.
  Future<void> initializeTerrainTexturing() async {
    if (_terrainTexturingEnabled) return;

    print('[WebGLRenderer] Initializing terrain texturing...');

    try {
      // Create texture manager and load terrain textures
      _textureManager = TextureManager(gl);
      await _textureManager!.initialize();

      // Create terrain shader
      _terrainShader = ShaderProgram.fromSource(
        gl,
        terrainVertexShader,
        terrainFragmentShader,
      );

      _terrainTexturingEnabled = true;
      print('[WebGLRenderer] Terrain texturing initialized successfully');
    } catch (e) {
      print('[WebGLRenderer] Failed to initialize terrain texturing: $e');
      _terrainTexturingEnabled = false;
    }
  }

  /// Check if terrain texturing is enabled
  bool get terrainTexturingEnabled => _terrainTexturingEnabled;

  /// Get the texture manager
  TextureManager? get textureManager => _textureManager;

  /// Clear the screen
  void clear() {
    gl.clear(0x00004000 | 0x00000100); // COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT
  }

  /// Render a mesh with given transform and camera
  ///
  /// This is the main rendering method - call once per object per frame.
  void render(Mesh mesh, Transform3d transform, Camera3D camera) {
    // Get or create buffers for this mesh
    final buffers = _getOrCreateBuffers(mesh);

    // Activate shader
    shader.use();

    // Set matrices
    shader.setUniformMatrix4('uProjection', camera.getProjectionMatrix());
    shader.setUniformMatrix4('uView', camera.getViewMatrix());
    shader.setUniformMatrix4('uModel', transform.toMatrix());

    // Set lighting uniforms
    shader.setUniformVector3('uLightPos', lightPosition);
    shader.setUniformVector3('uLightColor', lightColor);
    shader.setUniformVector3('uAmbientColor', ambientColor);

    // Bind and configure position attribute
    final positionLoc = shader.getAttribLocation('aPosition');
    if (positionLoc >= 0) {
      gl.bindBuffer(0x8892, buffers.vertexBuffer); // ARRAY_BUFFER
      gl.enableVertexAttribArray(positionLoc);
      gl.vertexAttribPointer(positionLoc, 3, 0x1406, false, 0, 0); // FLOAT
    }

    // Bind and configure normal attribute
    final normalLoc = shader.getAttribLocation('aNormal');
    if (normalLoc >= 0 && buffers.normalBuffer != null) {
      gl.bindBuffer(0x8892, buffers.normalBuffer); // ARRAY_BUFFER
      gl.enableVertexAttribArray(normalLoc);
      gl.vertexAttribPointer(normalLoc, 3, 0x1406, false, 0, 0); // FLOAT
    }

    // Bind and configure color attribute
    final colorLoc = shader.getAttribLocation('aColor');
    if (colorLoc >= 0) {
      if (buffers.colorBuffer != null) {
        gl.bindBuffer(0x8892, buffers.colorBuffer); // ARRAY_BUFFER
        gl.enableVertexAttribArray(colorLoc);
        gl.vertexAttribPointer(colorLoc, 4, 0x1406, false, 0, 0); // FLOAT
      } else {
        // Default white color if no vertex colors
        gl.disableVertexAttribArray(colorLoc);
        gl.vertexAttrib4f(colorLoc, 1.0, 1.0, 1.0, 1.0);
      }
    }

    // Bind indices and draw
    gl.bindBuffer(0x8893, buffers.indexBuffer); // ELEMENT_ARRAY_BUFFER
    gl.drawElements(0x0004, mesh.indices.length, 0x1403, 0); // TRIANGLES, UNSIGNED_SHORT

    // Cleanup
    if (positionLoc >= 0) gl.disableVertexAttribArray(positionLoc);
    if (normalLoc >= 0) gl.disableVertexAttribArray(normalLoc);
    if (colorLoc >= 0) gl.disableVertexAttribArray(colorLoc);
  }

  /// Render a terrain chunk with texture splatting
  ///
  /// Uses the terrain shader with multi-texture blending based on
  /// height and slope. Falls back to regular rendering if terrain
  /// texturing is not initialized.
  ///
  /// Parameters:
  /// - chunk: Terrain chunk with LOD meshes and splat map
  /// - transform: World transform for the chunk
  /// - camera: Camera for view/projection matrices
  void renderTerrain(
    TerrainChunkWithLOD chunk,
    Transform3d transform,
    Camera3D camera,
  ) {
    try {
      // Fall back to regular rendering if texturing not enabled
      if (!_terrainTexturingEnabled || _terrainShader == null || _textureManager == null) {
        render(chunk.currentMesh, transform, camera);
        return;
      }

    final mesh = chunk.currentMesh;

    // Debug: Check if mesh has texCoords
    if (mesh.texCoords == null && !_loggedMissingTexCoords) {
      print('[WebGLRenderer] Warning: Terrain mesh missing texCoords!');
      _loggedMissingTexCoords = true;
    }

    final buffers = _getOrCreateBuffers(mesh);
    final terrainShader = _terrainShader!;

    // Activate terrain shader
    terrainShader.use();

    // Set transform matrices
    terrainShader.setUniformMatrix4('uProjection', camera.getProjectionMatrix());
    terrainShader.setUniformMatrix4('uView', camera.getViewMatrix());
    terrainShader.setUniformMatrix4('uModel', transform.toMatrix());

    // Set lighting uniforms
    terrainShader.setUniformVector3('uLightPos', lightPosition);
    terrainShader.setUniformVector3('uLightColor', lightColor);
    terrainShader.setUniformVector3('uAmbientColor', ambientColor);
    terrainShader.setUniformVector3('uCameraPos', camera.position);

    // Set terrain configuration
    terrainShader.setUniformFloat('uTextureScale', TerrainConfig.textureScale);
    terrainShader.setUniformFloat('uChunkSize', chunk.size * chunk.tileSize);
    terrainShader.setUniformFloat('uDetailDistance', TerrainConfig.detailDistance);
    terrainShader.setUniformFloat('uMaxHeight', TerrainConfig.maxHeight);

    // Feature toggles removed - using simplified shader for debugging
    // terrainShader.setUniformBool('uUseNormalMaps', TerrainConfig.useNormalMaps);
    // terrainShader.setUniformBool('uUseDetailMap', TerrainConfig.useDetailMaps);
    // terrainShader.setUniformBool('uUseSplatMap', chunk.hasSplatMap && chunk.splatMapTexture != null);

    // Set height/slope thresholds for auto-blending
    terrainShader.setUniformFloat('uSandMaxHeight', TerrainConfig.sandMaxHeight);
    terrainShader.setUniformFloat('uGrassMaxHeight', TerrainConfig.grassMaxHeight);
    terrainShader.setUniformFloat('uRockMinSlope', TerrainConfig.rockMinSlope);

    // Bind terrain textures
    _textureManager!.bindTerrainTextures();

    // Set texture sampler uniforms
    terrainShader.setUniformSampler2D('uTexGrass', 0);
    terrainShader.setUniformSampler2D('uTexDirt', 1);
    terrainShader.setUniformSampler2D('uTexRock', 2);
    terrainShader.setUniformSampler2D('uTexSand', 3);
    terrainShader.setUniformSampler2D('uNormGrass', 4);
    terrainShader.setUniformSampler2D('uNormDirt', 5);
    terrainShader.setUniformSampler2D('uNormRock', 6);
    terrainShader.setUniformSampler2D('uNormSand', 7);
    terrainShader.setUniformSampler2D('uDetail', 8);

    // Bind splat map texture if available
    if (chunk.hasSplatMap) {
      // Create splat map texture if not already created
      if (chunk.splatMapTexture == null && chunk.splatMapData != null) {
        chunk.splatMapTexture = _textureManager!.createSplatMapTexture(
          chunk.splatMapData!,
          chunk.splatMapResolution,
        );
      }

      if (chunk.splatMapTexture != null) {
        gl.activeTexture(0x84C0 + 9); // TEXTURE9
        gl.bindTexture(0x0DE1, chunk.splatMapTexture); // TEXTURE_2D
        terrainShader.setUniformSampler2D('uSplatMap', 9);
      }
    }

    // Bind position attribute
    final positionLoc = terrainShader.getAttribLocation('aPosition');
    if (positionLoc >= 0) {
      gl.bindBuffer(0x8892, buffers.vertexBuffer); // ARRAY_BUFFER
      gl.enableVertexAttribArray(positionLoc);
      gl.vertexAttribPointer(positionLoc, 3, 0x1406, false, 0, 0); // FLOAT
    }

    // Bind normal attribute
    final normalLoc = terrainShader.getAttribLocation('aNormal');
    if (normalLoc >= 0 && buffers.normalBuffer != null) {
      gl.bindBuffer(0x8892, buffers.normalBuffer); // ARRAY_BUFFER
      gl.enableVertexAttribArray(normalLoc);
      gl.vertexAttribPointer(normalLoc, 3, 0x1406, false, 0, 0); // FLOAT
    }

    // Bind texture coordinate attribute
    final texCoordLoc = terrainShader.getAttribLocation('aTexCoord');
    if (texCoordLoc >= 0) {
      if (buffers.texCoordBuffer != null) {
        gl.bindBuffer(0x8892, buffers.texCoordBuffer); // ARRAY_BUFFER
        gl.enableVertexAttribArray(texCoordLoc);
        gl.vertexAttribPointer(texCoordLoc, 2, 0x1406, false, 0, 0); // FLOAT
      } else {
        // Provide default UV coordinates if buffer is missing
        gl.disableVertexAttribArray(texCoordLoc);
        gl.vertexAttrib2f(texCoordLoc, 0.0, 0.0);
      }
    }

    // Draw the terrain
    gl.bindBuffer(0x8893, buffers.indexBuffer); // ELEMENT_ARRAY_BUFFER
    gl.drawElements(0x0004, mesh.indices.length, 0x1403, 0); // TRIANGLES, UNSIGNED_SHORT

    // Cleanup
    if (positionLoc >= 0) gl.disableVertexAttribArray(positionLoc);
    if (normalLoc >= 0) gl.disableVertexAttribArray(normalLoc);
    if (texCoordLoc >= 0) gl.disableVertexAttribArray(texCoordLoc);

    // Unbind textures
    for (int i = 0; i <= 9; i++) {
      gl.activeTexture(0x84C0 + i); // TEXTURE0 + i
      gl.bindTexture(0x0DE1, null); // TEXTURE_2D
    }
    } catch (e, stackTrace) {
      print('[WebGLRenderer] ERROR in renderTerrain: $e');
      print('[WebGLRenderer] Stack: $stackTrace');
      // Fall back to regular rendering on error
      render(chunk.currentMesh, transform, camera);
    }
  }

  /// Get or create GPU buffers for a mesh
  _MeshBuffers _getOrCreateBuffers(Mesh mesh) {
    if (_meshBuffers.containsKey(mesh)) {
      return _meshBuffers[mesh]!;
    }

    final buffers = _MeshBuffers(
      vertexBuffer: _createBuffer(0x8892, mesh.vertices), // ARRAY_BUFFER
      indexBuffer: _createBuffer(0x8893, mesh.indices), // ELEMENT_ARRAY_BUFFER
      normalBuffer: mesh.normals != null
          ? _createBuffer(0x8892, mesh.normals!) // ARRAY_BUFFER
          : null,
      colorBuffer: mesh.colors != null
          ? _createBuffer(0x8892, mesh.colors!) // ARRAY_BUFFER
          : null,
      texCoordBuffer: mesh.texCoords != null
          ? _createBuffer(0x8892, mesh.texCoords!) // ARRAY_BUFFER
          : null,
    );

    _meshBuffers[mesh] = buffers;
    return buffers;
  }

  /// Create a WebGL buffer and upload data
  dynamic _createBuffer(int target, dynamic data) { // Returns WebGL Buffer
    final buffer = gl.createBuffer();
    if (buffer == null) {
      throw Exception('Failed to create WebGL buffer');
    }

    gl.bindBuffer(target, buffer);
    gl.bufferData(target, data, 0x88E4); // STATIC_DRAW
    gl.bindBuffer(target, null);

    return buffer;
  }

  /// Delete mesh buffers (use when mesh is no longer needed)
  void deleteMeshBuffers(Mesh mesh) {
    final buffers = _meshBuffers.remove(mesh);
    if (buffers != null) {
      gl.deleteBuffer(buffers.vertexBuffer);
      gl.deleteBuffer(buffers.indexBuffer);
      if (buffers.normalBuffer != null) gl.deleteBuffer(buffers.normalBuffer);
      if (buffers.colorBuffer != null) gl.deleteBuffer(buffers.colorBuffer);
      if (buffers.texCoordBuffer != null) gl.deleteBuffer(buffers.texCoordBuffer);
    }
  }

  /// Resize renderer (call when canvas size changes)
  void resize(int width, int height) {
    canvas.width = width;
    canvas.height = height;
    gl.viewport(0, 0, width, height);
  }

  /// Dispose all resources
  void dispose() {
    // Delete all mesh buffers
    for (final buffers in _meshBuffers.values) {
      gl.deleteBuffer(buffers.vertexBuffer);
      gl.deleteBuffer(buffers.indexBuffer);
      if (buffers.normalBuffer != null) gl.deleteBuffer(buffers.normalBuffer);
      if (buffers.colorBuffer != null) gl.deleteBuffer(buffers.colorBuffer);
      if (buffers.texCoordBuffer != null) gl.deleteBuffer(buffers.texCoordBuffer);
    }
    _meshBuffers.clear();

    // Delete shaders
    shader.dispose();
    _terrainShader?.dispose();

    // Delete texture manager
    _textureManager?.dispose();

    print('WebGLRenderer disposed');
  }
}

/// Internal class to store GPU buffers for a mesh
class _MeshBuffers {
  final dynamic vertexBuffer; // WebGL Buffer
  final dynamic indexBuffer; // WebGL Buffer
  final dynamic normalBuffer; // WebGL Buffer
  final dynamic colorBuffer; // WebGL Buffer
  final dynamic texCoordBuffer; // WebGL Buffer

  _MeshBuffers({
    required this.vertexBuffer,
    required this.indexBuffer,
    this.normalBuffer,
    this.colorBuffer,
    this.texCoordBuffer,
  });
}
