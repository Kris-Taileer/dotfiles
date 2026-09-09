#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec2 v_coords;
uniform vec2 size;
uniform float u_time;

#define WAVE_SPEED 1.0
#define LINE_COUNT 6.0
#define AMPLITUDE 1.0
#define ROTATION 0.0

#define S smoothstep

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

mat2 rot2(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

vec3 curtainLine(vec2 uv, float speed, float freq, vec3 c, float t) {
    uv.x += S(1.0, 0.0, abs(uv.y)) * sin(t * speed + uv.y * freq) * 0.2;
    float lw = 0.06 * S(0.2, 0.9, abs(uv.y));
    float l = S(lw, 0.0, abs(uv.x) - 0.004);
    float fade = S(1.0, 0.3, abs(uv.y));
    return l * c * fade;
}

void main() {
    vec2 uv = (vec2(v_coords.x, 1.0 - v_coords.y) * size - 0.5 * size) / size.y;
    uv = rot2(ROTATION) * uv;

    float t = u_time * WAVE_SPEED;
    int lineCount = int(LINE_COUNT);

    vec3 col = vec3(0.0);

    for (int i = 0; i < 12; i++) {
        if (i >= lineCount) break;
        float fi = float(i);
        float frac = fi / max(LINE_COUNT - 1.0, 1.0);

        float speed = (0.6 + frac * 0.5);
        float freq = (4.0 + frac * 2.0) * AMPLITUDE;

        vec3 warmAmber = vec3(0.85, 0.55, 0.25);
        vec3 coolTeal = vec3(0.2, 0.6, 0.65);
        vec3 lineCol = mix(warmAmber, coolTeal, frac) * (0.5 + frac * 0.5);

        float yBlend = S(-0.4, 0.5, uv.y);
        vec3 pixelCol = mix(warmAmber, coolTeal, yBlend) * (0.4 + frac * 0.6);
        lineCol = mix(lineCol, pixelCol, 0.6);

        float drift = sin(t * 0.15 + fi * 1.3) * 0.03;
        float nOff = noise(vec2(uv.y * 2.0 + fi * 3.7, t * 0.1 + fi)) * 0.015;

        col += curtainLine(uv + vec2(nOff + drift, 0.0), speed, freq, lineCol, t);
    }

    float vig = 1.0 - dot(uv, uv) * 0.4;
    col *= max(vig, 0.0);

    gl_FragColor = vec4(col, 1.0);
}
