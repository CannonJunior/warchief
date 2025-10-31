import 'dart:html' as html;
import 'dart:web_gl' as webgl;
import 'package:vector_math/vector_math.dart';

/// ShaderProgram - Manages WebGL shader compilation and uniform setting
///
/// Wraps vertex and fragment shaders, provides methods to set uniforms.
/// This is the core of the WebGL rendering pipeline.
///
/// Usage:
/// ```dart
/// final shader = ShaderProgram(gl, vertexSource, fragmentSource);
/// shader.use();
/// shader.setUniformMatrix4('uProjection', projectionMatrix);
/// shader.setUniformMatrix4('uView', viewMatrix);
/// shader.setUniformMatrix4('uModel', modelMatrix);
/// ```
class ShaderProgram {
  final webgl.RenderingContext gl;
  final webgl.Program program;

  /// Cache uniform locations for performance
  final Map<String, webgl.UniformLocation> _uniformLocations = {};

  /// Cache attribute locations for performance
  final Map<String, int> _attribLocations = {};

  ShaderProgram._(this.gl, this.program);

  /// Create a shader program from vertex and fragment shader source
  factory ShaderProgram.fromSource(
    webgl.RenderingContext gl,
    String vertexSource,
    String fragmentSource,
  ) {
    // Compile vertex shader
    final vertexShader = _compileShader(gl, 0x8B31, vertexSource); // VERTEX_SHADER
    if (vertexShader == null) {
      throw Exception('Failed to compile vertex shader');
    }

    // Compile fragment shader
    final fragmentShader = _compileShader(gl, 0x8B30, fragmentSource); // FRAGMENT_SHADER
    if (fragmentShader == null) {
      gl.deleteShader(vertexShader);
      throw Exception('Failed to compile fragment shader');
    }

    // Link program
    final program = gl.createProgram();
    if (program == null) {
      gl.deleteShader(vertexShader);
      gl.deleteShader(fragmentShader);
      throw Exception('Failed to create shader program');
    }

    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    // Check link status
    if (gl.getProgramParameter(program, 0x8B82) == 0) { // LINK_STATUS
      final error = gl.getProgramInfoLog(program);
      gl.deleteProgram(program);
      gl.deleteShader(vertexShader);
      gl.deleteShader(fragmentShader);
      throw Exception('Failed to link shader program: $error');
    }

    // Cleanup shaders (they're now part of the program)
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    return ShaderProgram._(gl, program);
  }

  /// Compile a shader from source
  static webgl.Shader? _compileShader(
    webgl.RenderingContext gl,
    int type,
    String source,
  ) {
    final shader = gl.createShader(type);
    if (shader == null) return null;

    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (gl.getShaderParameter(shader, 0x8B81) == 0) { // COMPILE_STATUS
      final error = gl.getShaderInfoLog(shader);
      print('Shader compile error: $error');
      print('Source:\n$source');
      gl.deleteShader(shader);
      return null;
    }

    return shader;
  }

  /// Activate this shader program for rendering
  void use() {
    gl.useProgram(program);
  }

  /// Get uniform location (cached)
  webgl.UniformLocation? _getUniformLocation(String name) {
    if (_uniformLocations.containsKey(name)) {
      return _uniformLocations[name];
    }

    final location = gl.getUniformLocation(program, name);
    if (location != null) {
      _uniformLocations[name] = location;
    }

    return location;
  }

  /// Get attribute location (cached)
  int getAttribLocation(String name) {
    if (_attribLocations.containsKey(name)) {
      return _attribLocations[name]!;
    }

    final location = gl.getAttribLocation(program, name);
    _attribLocations[name] = location;
    return location;
  }

  /// Set a Matrix4 uniform
  void setUniformMatrix4(String name, Matrix4 matrix) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniformMatrix4fv(location, false, matrix.storage);
    }
  }

  /// Set a Vector3 uniform
  void setUniformVector3(String name, Vector3 vector) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniform3f(location, vector.x, vector.y, vector.z);
    }
  }

  /// Set a Vector4 uniform
  void setUniformVector4(String name, Vector4 vector) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniform4f(location, vector.x, vector.y, vector.z, vector.w);
    }
  }

  /// Set a float uniform
  void setUniformFloat(String name, double value) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniform1f(location, value);
    }
  }

  /// Set an int uniform
  void setUniformInt(String name, int value) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniform1i(location, value);
    }
  }

  /// Dispose this shader program
  void dispose() {
    gl.deleteProgram(program);
    _uniformLocations.clear();
    _attribLocations.clear();
  }
}

/// Default vertex shader for basic 3D rendering
const String defaultVertexShader = '''
attribute vec3 aPosition;
attribute vec3 aNormal;
attribute vec4 aColor;

uniform mat4 uProjection;
uniform mat4 uView;
uniform mat4 uModel;

varying vec3 vNormal;
varying vec4 vColor;
varying vec3 vFragPos;

void main() {
  vec4 worldPos = uModel * vec4(aPosition, 1.0);
  vFragPos = worldPos.xyz;
  vNormal = mat3(uModel) * aNormal;
  vColor = aColor;
  gl_Position = uProjection * uView * worldPos;
}
''';

/// Default fragment shader for basic 3D rendering with lighting
const String defaultFragmentShader = '''
precision mediump float;

varying vec3 vNormal;
varying vec4 vColor;
varying vec3 vFragPos;

uniform vec3 uLightPos;
uniform vec3 uLightColor;
uniform vec3 uAmbientColor;

void main() {
  // Ambient lighting
  vec3 ambient = uAmbientColor;

  // Diffuse lighting
  vec3 norm = normalize(vNormal);
  vec3 lightDir = normalize(uLightPos - vFragPos);
  float diff = max(dot(norm, lightDir), 0.0);
  vec3 diffuse = diff * uLightColor;

  // Combine lighting with vertex color
  vec3 result = (ambient + diffuse) * vColor.rgb;
  gl_FragColor = vec4(result, vColor.a);
}
''';

/// Simple unlit vertex shader (no lighting calculations)
const String unlitVertexShader = '''
attribute vec3 aPosition;
attribute vec4 aColor;

uniform mat4 uProjection;
uniform mat4 uView;
uniform mat4 uModel;

varying vec4 vColor;

void main() {
  vColor = aColor;
  gl_Position = uProjection * uView * uModel * vec4(aPosition, 1.0);
}
''';

/// Simple unlit fragment shader (just vertex colors)
const String unlitFragmentShader = '''
precision mediump float;

varying vec4 vColor;

void main() {
  gl_FragColor = vColor;
}
''';
