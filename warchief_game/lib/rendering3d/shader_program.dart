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
  final dynamic gl; // WebGL RenderingContext (typed as dynamic for compatibility)
  final dynamic program; // WebGL Program

  /// Cache uniform locations for performance
  final Map<String, dynamic> _uniformLocations = {}; // WebGL UniformLocation

  /// Cache attribute locations for performance
  final Map<String, int> _attribLocations = {};

  ShaderProgram._(this.gl, this.program);

  /// Create a shader program from vertex and fragment shader source
  factory ShaderProgram.fromSource(
    dynamic gl, // WebGL RenderingContext
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
  static dynamic _compileShader( // Returns WebGL Shader
    dynamic gl, // WebGL RenderingContext
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
  /// Returns null if uniform doesn't exist (or was optimized out)
  dynamic _getUniformLocation(String name) { // Returns WebGL UniformLocation
    if (_uniformLocations.containsKey(name)) {
      return _uniformLocations[name];
    }

    // Wrap in try-catch to handle null assertions in dart:web_gl
    try {
      final location = gl.getUniformLocation(program, name);
      if (location != null) {
        _uniformLocations[name] = location;
      }
      return location;
    } catch (e) {
      // Uniform doesn't exist or was optimized out
      // This is normal for unused uniforms
      return null;
    }
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

  /// Set a boolean uniform (as int: 0 or 1)
  void setUniformBool(String name, bool value) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniform1i(location, value ? 1 : 0);
    }
  }

  /// Set a sampler2D uniform (texture unit index)
  ///
  /// Use this to bind textures to samplers in shaders.
  /// The textureUnit should match the texture unit where the texture is bound.
  ///
  /// Example:
  /// ```dart
  /// gl.activeTexture(gl.TEXTURE0);
  /// gl.bindTexture(gl.TEXTURE_2D, myTexture);
  /// shader.setUniformSampler2D('uTexture', 0);  // Unit 0
  /// ```
  void setUniformSampler2D(String name, int textureUnit) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniform1i(location, textureUnit);
    }
  }

  /// Set a Vector2 uniform
  void setUniformVector2(String name, double x, double y) {
    final location = _getUniformLocation(name);
    if (location != null) {
      gl.uniform2f(location, x, y);
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
