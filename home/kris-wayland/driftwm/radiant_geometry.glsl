#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec2 v_coords;
uniform vec2 size;
uniform float u_time;

#define ROTATION_SPEED 0.3
#define COMPLEXITY 1.0
#define PATTERN_MIX 0.0

#define PI 3.14159265359
#define TAU 6.28318530718
#define SQRT3 1.7320508
#define PHI 1.6180339887

mat2 rot(float a) {
  float c = cos(a), s = sin(a);
  return mat2(c, -s, s, c);
}

vec2 polarFold(vec2 p, float n) {
  float angle = atan(p.y, p.x);
  float sector = TAU / n;
  angle = mod(angle + sector * 0.5, sector) - sector * 0.5;
  angle = abs(angle);
  float r = length(p);
  return vec2(cos(angle), sin(angle)) * r;
}

float sdSegment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

float sdPolygon(vec2 p, float r, float n) {
  float angle = atan(p.y, p.x);
  float sector = TAU / n;
  float a = mod(angle + sector * 0.5, sector) - sector * 0.5;
  float rp = length(p);
  vec2 q = vec2(cos(a), abs(sin(a))) * rp;
  vec2 edge = vec2(cos(sector * 0.5), sin(sector * 0.5)) * r;
  vec2 d = q - edge * clamp(dot(q, edge) / dot(edge, edge), 0.0, 1.0);
  return length(d) * sign(q.x * edge.y - q.y * edge.x);
}

float sdCircle(vec2 p, float r) {
  return length(p) - r;
}

vec3 glowLine(float d, vec3 coreColor, vec3 bloomColor, float lineWidth, float bloomWidth) {
  float core = lineWidth / (abs(d) + lineWidth);
  core = pow(core, 2.0);
  float bloom = bloomWidth / (abs(d) + bloomWidth);
  bloom = pow(bloom, 1.5);
  return coreColor * core + bloomColor * bloom * 0.4;
}

float starPattern6(vec2 p, float scale, float t) {
  p *= scale;
  float d = 1e9;
  vec2 fp = polarFold(p, 12.0);
  float breathe = 1.0 + 0.03 * sin(t * 0.7);
  vec2 a1 = vec2(0.5 * breathe, 0.0);
  vec2 b1 = vec2(0.35 * breathe, 0.15 * breathe);
  d = min(d, sdSegment(fp, a1, b1));
  vec2 a2 = vec2(0.35 * breathe, 0.15 * breathe);
  vec2 b2 = vec2(0.22 * breathe, 0.0);
  d = min(d, sdSegment(fp, a2, b2));
  vec2 a3 = vec2(0.22 * breathe, 0.0);
  vec2 b3 = vec2(0.12 * breathe, 0.07 * breathe);
  d = min(d, sdSegment(fp, a3, b3));
  vec2 a4 = vec2(0.12 * breathe, 0.07 * breathe);
  vec2 b4 = vec2(0.0, 0.0);
  d = min(d, sdSegment(fp, a4, b4));
  float outerRing = abs(length(p) - 0.5 * breathe);
  d = min(d, outerRing);
  float innerRing = abs(length(p) - 0.22 * breathe);
  d = min(d, innerRing);
  return d / scale;
}

float starPattern8(vec2 p, float scale, float t) {
  p *= scale;
  float d = 1e9;
  vec2 fp = polarFold(p, 16.0);
  float breathe = 1.0 + 0.025 * sin(t * 0.5 + 1.0);
  vec2 a1 = vec2(0.45 * breathe, 0.0);
  vec2 b1 = vec2(0.32 * breathe, 0.13 * breathe);
  d = min(d, sdSegment(fp, a1, b1));
  vec2 a2 = vec2(0.32 * breathe, 0.13 * breathe);
  vec2 b2 = vec2(0.18 * breathe, 0.0);
  d = min(d, sdSegment(fp, a2, b2));
  vec2 a3 = vec2(0.18 * breathe, 0.0);
  vec2 b3 = vec2(0.10 * breathe, 0.06 * breathe);
  d = min(d, sdSegment(fp, a3, b3));
  vec2 a4 = vec2(0.10 * breathe, 0.06 * breathe);
  vec2 b4 = vec2(0.0, 0.0);
  d = min(d, sdSegment(fp, a4, b4));
  float ring1 = abs(length(p) - 0.45 * breathe);
  float ring2 = abs(length(p) - 0.18 * breathe);
  d = min(d, ring1);
  d = min(d, ring2);
  return d / scale;
}

float hexTileStars(vec2 p, float scale, float t, float rotAngle) {
  p = rot(rotAngle) * p;
  p *= scale;
  vec2 s = vec2(1.0, SQRT3);
  vec2 h = s * 0.5;
  vec2 a = mod(p, s) - h;
  vec2 b = mod(p - h, s) - h;
  vec2 gUV = dot(a, a) < dot(b, b) ? a : b;
  float d = starPattern6(gUV, 1.8, t);
  return d / scale;
}

float squareTileStars(vec2 p, float scale, float t, float rotAngle) {
  p = rot(rotAngle) * p;
  p *= scale;
  vec2 cell = mod(p + 0.5, 1.0) - 0.5;
  float d = starPattern8(cell, 1.6, t);
  return d / scale;
}

float girihPattern(vec2 p, float scale, float t) {
  p *= scale;
  float d = 1e9;
  float breathe = 1.0 + 0.02 * sin(t * 0.6 + 2.0);
  vec2 fp = polarFold(p, 10.0);
  vec2 a1 = vec2(0.5 * breathe, 0.0);
  vec2 b1 = vec2(0.38 * breathe, 0.18 * breathe);
  d = min(d, sdSegment(fp, a1, b1));
  vec2 a2 = vec2(0.38 * breathe, 0.18 * breathe);
  vec2 b2 = vec2(0.25 * breathe, 0.05 * breathe);
  d = min(d, sdSegment(fp, a2, b2));
  vec2 a3 = vec2(0.25 * breathe, 0.05 * breathe);
  vec2 b3 = vec2(0.15 * breathe, 0.12 * breathe);
  d = min(d, sdSegment(fp, a3, b3));
  vec2 a4 = vec2(0.15 * breathe, 0.12 * breathe);
  vec2 b4 = vec2(0.0, 0.0);
  d = min(d, sdSegment(fp, a4, b4));
  float ring1 = abs(length(p) - 0.5 * breathe);
  float ring2 = abs(length(p) - 0.32 * breathe);
  float ring3 = abs(length(p) - 0.15 * breathe);
  d = min(d, ring1);
  d = min(d, ring2);
  d = min(d, ring3);
  return d / scale;
}

vec3 radiantGeometry(vec2 uv, float t, float rotSpeed, float complexity) {
  vec3 col = vec3(0.01, 0.005, 0.020);

  float rot1 = t * rotSpeed * 0.04;
  float d1 = hexTileStars(uv, 2.5 * complexity, t, rot1);
  vec3 dimPurp = vec3(0.18, 0.08, 0.32);
  vec3 medPurp = vec3(0.45, 0.18, 0.72);
  col += glowLine(d1, medPurp * 0.7, dimPurp, 0.0015, 0.012);

  float rot2 = -t * rotSpeed * 0.06;
  float d2 = squareTileStars(uv, 3.5 * complexity, t, rot2);
  vec3 brightViolet = vec3(0.68, 0.35, 0.92);
  col += glowLine(d2, brightViolet * 0.6, dimPurp * 0.8, 0.0012, 0.010);

  float rot3 = t * rotSpeed * 0.09;
  float d3 = girihPattern(uv, 4.0 * complexity, t);
  vec2 uvRot3 = rot(rot3) * uv;
  float d3r = girihPattern(uvRot3, 4.0 * complexity, t);
  vec3 coreGlow = vec3(0.88, 0.62, 1.0);
  col += glowLine(d3r, coreGlow * 0.4, medPurp * 0.5, 0.001, 0.008);

  float centralRot = t * rotSpeed * 0.03;
  vec2 centralUV = rot(centralRot) * uv;
  float dCentral = starPattern8(centralUV, 2.2, t);
  float centralFade = smoothstep(0.5, 0.15, length(uv));
  vec3 hotLavender = vec3(0.95, 0.80, 1.0);
  col += glowLine(dCentral, hotLavender * 0.5, coreGlow * 0.3, 0.002, 0.018) * centralFade;

  float rot5 = -t * rotSpeed * 0.035;
  float d5 = hexTileStars(uv, 3.0 * complexity, t, rot5);
  col += glowLine(d5, medPurp * 0.45, dimPurp * 0.5, 0.001, 0.008);

  float r = length(uv);
  float breathe = 1.0 + 0.04 * sin(t * 0.4);
  float ringD = 1e9;
  float rScale = 0.12 * breathe;
  float pr0 = abs(sdPolygon(rot(t * rotSpeed * 0.02) * uv, rScale * 1.0, 6.0));
  float pr1 = abs(sdPolygon(rot(-t * rotSpeed * 0.025) * uv, rScale * 2.0, 8.0));
  float pr2 = abs(sdPolygon(rot(t * rotSpeed * 0.015) * uv, rScale * 3.0, 12.0));
  float pr3 = abs(sdPolygon(rot(-t * rotSpeed * 0.018) * uv, rScale * 4.0, 6.0));
  ringD = min(ringD, pr0);
  ringD = min(ringD, pr1);
  ringD = min(ringD, pr2);
  ringD = min(ringD, pr3);
  col += glowLine(ringD, brightViolet * 0.3, dimPurp * 0.3, 0.001, 0.006);

  float centerGlow = exp(-r * r * 4.0) * 0.08;
  col += vec3(0.35, 0.15, 0.55) * centerGlow;

  float pulse = 0.92 + 0.08 * sin(t * 0.3);
  col *= pulse;

  float vig = 1.0 - r * r * 0.6;
  vig = max(vig, 0.0);
  col *= (0.5 + vig * 0.5);

  return col;
}

vec3 gold(float t) {
  vec3 a = vec3(0.28, 0.12, 0.48);
  vec3 b = vec3(0.28, 0.18, 0.38);
  vec3 c = vec3(0.9, 1.1, 0.7);
  vec3 d = vec3(0.15, 0.0, 0.30);
  return a + b * cos(TAU * (c * t + d));
}

float hexDist(vec2 p) {
  p = abs(p);
  return max(p.x + p.y * 0.577350269, p.y * 1.154700538);
}

float triDist(vec2 p) {
  float k = sqrt(3.0);
  p.x = abs(p.x) - 1.0;
  p.y = p.y + 1.0 / k;
  if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
  p.x -= clamp(p.x, -2.0, 0.0);
  return -length(p) * sign(p.y);
}

float mandalaLayer(vec2 uv, float time, float layer, float totalLayers, float rotSpd) {
  float t = layer / totalLayers;
  float radius = 0.08 + t * 0.38;
  float speed = rotSpd * (1.5 - t * 1.2);
  float direction = mod(layer, 2.0) < 1.0 ? 1.0 : -1.0;
  float rot_angle = time * speed * direction + layer * PHI;
  vec2 p = rot(rot_angle) * uv;
  float d = 1e9;
  float symmetry = 6.0 + floor(layer * 1.5);
  float angle = atan(p.y, p.x);
  float r = length(p);
  float sector = TAU / symmetry;
  float a = mod(angle + sector * 0.5, sector) - sector * 0.5;
  vec2 sp = vec2(cos(a), sin(a)) * r;
  float ring = abs(r - radius) - 0.003 * (1.0 + t);
  d = min(d, ring);
  float petalR = radius * 0.35 / PHI;
  vec2 petalCenter = vec2(radius, 0.0);
  float petal = abs(length(sp - petalCenter) - petalR) - 0.002;
  d = min(d, petal);
  vec2 innerPetalCenter = vec2(radius * 0.65, 0.0);
  float innerPetalR = radius * 0.25;
  float innerPetal = abs(length(sp - innerPetalCenter) - innerPetalR) - 0.0015;
  d = min(d, innerPetal);
  float spoke = abs(sp.y) - 0.001;
  float spokeMask = smoothstep(radius - 0.05, radius - 0.01, r) * smoothstep(radius + 0.05, radius + 0.01, r);
  d = min(d, spoke / max(spokeMask, 0.001));
  float hexR = 0.012 + t * 0.008;
  vec2 hexPos = vec2(radius, 0.0);
  float hex = hexDist(sp - hexPos) - hexR;
  d = min(d, hex);
  if (layer > 1.0) {
    vec2 triPos = vec2(radius * 0.5, 0.0);
    vec2 tp = (sp - triPos) * 60.0;
    float tri = triDist(tp) / 60.0;
    d = min(d, tri);
  }
  return d;
}

float goldenSpiral(vec2 uv, float time, float rotSpd) {
  float r = length(uv);
  float a = atan(uv.y, uv.x);
  float spiralPhase = log(max(r, 0.001)) / log(PHI) * PI * 0.5;
  float spiralD = abs(mod(a - spiralPhase + time * rotSpd * 0.2 + PI, TAU) - PI);
  spiralD = min(spiralD, abs(mod(a - spiralPhase + time * rotSpd * 0.2 + PI + PI, TAU) - PI));
  float fade = smoothstep(0.0, 0.05, r) * smoothstep(0.5, 0.35, r);
  return spiralD * fade + (1.0 - fade);
}

float fractalDetail(vec2 uv, float time, float rotSpd) {
  float d = 1e9;
  float scale = 1.0;
  float intensity = 0.0;
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    vec2 p = uv * scale;
    p = rot(time * rotSpd * (0.1 + fi * 0.05) * (mod(fi, 2.0) < 1.0 ? 1.0 : -1.0)) * p;
    float hexSize = 0.15 / scale;
    vec2 hexUV = p;
    float hx = hexDist(mod(hexUV + hexSize, hexSize * 2.0) - hexSize);
    float hexLine = abs(hx - hexSize * 0.4) - 0.001 * scale;
    intensity += smoothstep(0.003, 0.0, hexLine) * (0.15 / (1.0 + fi));
    scale *= PHI;
  }
  return intensity;
}

vec3 goldenThrone(vec2 uv, float t, float rotSpeed, float complexity) {
  vec3 col = vec3(0.0);
  float r = length(uv);

  float objectRadius = 0.48;
  float objectFade = smoothstep(objectRadius, objectRadius * 0.7, r);

  float gtComplexity = 2.0 + (complexity - 0.3) * (6.0 / 1.7);
  gtComplexity = clamp(gtComplexity, 2.0, 8.0);

  float totalGlow = 0.0;
  for (int i = 0; i < 8; i++) {
    if (float(i) >= gtComplexity) break;
    float fi = float(i);
    float layerD = mandalaLayer(uv, t, fi, gtComplexity, rotSpeed);
    float lineGlow = 0.0025 / (abs(layerD) + 0.0025);
    float bloom = 0.008 / (abs(layerD) + 0.008) * 0.3;
    float layerIntensity = (lineGlow + bloom);
    float colorT = fi / gtComplexity + t * 0.02;
    vec3 layerColor = gold(colorT);
    float brightness = 1.0 - fi / gtComplexity * 0.5;
    col += layerColor * layerIntensity * brightness * 0.6;
    totalGlow += layerIntensity * brightness;
  }

  float spiral = goldenSpiral(uv, t, rotSpeed);
  float spiralGlow = 0.015 / (spiral + 0.015);
  col += gold(0.7 + t * 0.01) * spiralGlow * 0.25;

  float fractal = fractalDetail(uv, t, rotSpeed);
  col += gold(0.3 + t * 0.03) * fractal * 0.4;

  float centerPulse = 0.8 + 0.2 * sin(t * 1.5);
  float centerGlow = 0.01 / (r * r + 0.01) * centerPulse;
  vec3 centerColor = vec3(0.90, 0.72, 1.0);
  col += centerColor * centerGlow * 0.08;

  float ringPulse = 0.9 + 0.1 * sin(t * 2.3 + 1.0);
  float innerRing = abs(r - 0.03 * ringPulse) - 0.002;
  float innerRingGlow = 0.003 / (abs(innerRing) + 0.003);
  col += vec3(0.88, 0.68, 1.0) * innerRingGlow * 0.3;

  float outerRing = abs(r - objectRadius + 0.01) - 0.003;
  float outerGlow = 0.004 / (abs(outerRing) + 0.004);
  col += gold(0.5 + t * 0.015) * outerGlow * 0.35;

  float outerRing2 = abs(r - objectRadius + 0.035) - 0.002;
  float outerGlow2 = 0.003 / (abs(outerRing2) + 0.003);
  col += gold(0.6) * outerGlow2 * 0.2;

  float dotAngle = atan(uv.y, uv.x);
  float dotSymmetry = 12.0;
  float dotA = mod(dotAngle + PI / dotSymmetry, TAU / dotSymmetry) - PI / dotSymmetry;
  vec2 dotP = vec2(cos(dotA), sin(dotA)) * r;
  vec2 dotCenter = vec2(objectRadius - 0.01, 0.0);
  float dotD = length(dotP - dotCenter) - 0.008;
  float dotGlow = 0.004 / (abs(dotD) + 0.004);
  col += vec3(0.90, 0.72, 1.0) * dotGlow * 0.3;

  col *= objectFade;

  float ambientGlow = exp(-r * r * 6.0) * 0.06;
  col += vec3(0.15, 0.08, 0.30) * ambientGlow;

  return col;
}

void main() {
  vec2 uv = (vec2(v_coords.x, 1.0 - v_coords.y) * size - size * 0.5) / min(size.x, size.y);
  float t = u_time;
  float rotSpeed = ROTATION_SPEED;
  float complexity = COMPLEXITY;
  float pat = clamp(PATTERN_MIX, 0.0, 1.0);

  vec3 col;

  if (pat < 0.001) {
    col = radiantGeometry(uv, t, rotSpeed, complexity);
  } else if (pat > 0.999) {
    col = goldenThrone(uv, t, rotSpeed, complexity);
  } else {
    vec3 colA = radiantGeometry(uv, t, rotSpeed, complexity);
    vec3 colB = goldenThrone(uv, t, rotSpeed, complexity);
    col = colA * (1.0 - pat * 0.5) + colB * pat;
  }

  col = col / (1.0 + col * 0.3);
  col = pow(col, vec3(1.05, 1.00, 0.93));

  gl_FragColor = vec4(col, 1.0);
}
