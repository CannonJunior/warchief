import 'dart:html' as html;
import 'package:vector_math/vector_math.dart';
import 'camera3d.dart';
import 'mesh.dart';
import 'math/transform3d.dart';
import 'shader_program.dart';

/// WebGLRenderer - Core 3D rendering engine using WebGL
///
/// Manages WebGL context, shader programs, buffers, and rendering pipeline.
/// This replaces Flame's 2D rendering for true 3D with dual-axis rotation.
///
/// Usage:
/// ```dart
/// final canvas = html.CanvasElement(width: 800, height: 600);
/// final renderer = WebGLRenderer(canvas);
/// renderer.clear();
/// renderer.render(mesh, transform, camera);
/// ```
class WebGLRenderer {
  final html.CanvasElement canvas;
  final dynamic gl; // WebGL RenderingContext (typed as dynamic for compatibility)

  /// Active shader program
  late ShaderProgram shader;

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
    }
    _meshBuffers.clear();

    // Delete shader
    shader.dispose();

    print('WebGLRenderer disposed');
  }
}

/// Internal class to store GPU buffers for a mesh
class _MeshBuffers {
  final dynamic vertexBuffer; // WebGL Buffer
  final dynamic indexBuffer; // WebGL Buffer
  final dynamic normalBuffer; // WebGL Buffer
  final dynamic colorBuffer; // WebGL Buffer

  _MeshBuffers({
    required this.vertexBuffer,
    required this.indexBuffer,
    this.normalBuffer,
    this.colorBuffer,
  });
}
