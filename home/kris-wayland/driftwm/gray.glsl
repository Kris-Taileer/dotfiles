#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec2 v_coords;
uniform vec2 size;
uniform float u_time;

void main(void) {
  vec2 uv = (2.0 * v_coords * size - size) / min(size.x, size.y);

  for(float i = 1.0; i < 10.0; i++) {
      uv.x += 0.6 / i * cos(i * 2.5* uv.y + u_time);
      uv.y += 0.6 / i * cos(i * 1.5 * uv.x + u_time);
  }


  gl_FragColor = vec4(vec3(0.1)/abs(sin(u_time-uv.y-uv.x)),1.0);
}
