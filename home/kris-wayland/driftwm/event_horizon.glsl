#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec2 v_coords;
uniform vec2 size;
uniform float u_time;

#define ROTATION_SPEED 0.3
#define DISK_INTENSITY 1.0
#define STARS_ONLY 0.0
#define TILT_OFFSET 0.0
#define ROLL 0.0
#define CHROMATIC 0.35

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float RS = 1.0;
const float ISCO = 3.0;
const float DISK_IN = 2.2;
const float DISK_OUT = 14.0;

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float gNoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(
        mix(hash(i), hash(i + vec2(1, 0)), u.x),
        mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(0.866, 0.5, -0.5, 0.866);
    for (int i = 0; i < 4; i++) {
        v += a * gNoise(p);
        p = rot * p * 2.03 + vec2(47.0, 13.0);
        a *= 0.49;
    }
    return v;
}

float fbmLite(vec2 p) {
    float v = 0.5 * gNoise(p);
    p = mat2(0.866, 0.5, -0.5, 0.866) * p * 2.03 + vec2(47.0, 13.0);
    v += 0.25 * gNoise(p);
    return v;
}

vec3 starField(vec3 rd) {
    float u = atan(rd.z, rd.x) / TAU + 0.5;
    float v = asin(clamp(rd.y, -0.999, 0.999)) / PI + 0.5;
    vec3 col = vec3(0.0);

    {
        vec2 cell = floor(vec2(u, v) * 55.0);
        vec2 f = fract(vec2(u, v) * 55.0);
        vec2 r = vec2(hash(cell), hash(cell + 127.1));
        float d = length(f - r);
        float b = pow(r.x, 10.0) * exp(-d * d * 500.0);
        col += mix(vec3(1.0, 0.65, 0.35), vec3(0.55, 0.75, 1.0), r.y) * b * 4.0;
    }
    {
        vec2 cell = floor(vec2(u, v) * 170.0);
        vec2 f = fract(vec2(u, v) * 170.0);
        vec2 r = vec2(hash(cell + 43.0), hash(cell + 91.0));
        float d = length(f - r);
        float b = pow(r.x, 18.0) * exp(-d * d * 1000.0);
        col += vec3(0.85, 0.88, 1.0) * b * 2.0;
    }

    float n = fbmLite(vec2(u, v) * 3.0) * fbmLite(vec2(u, v) * 5.5 + 10.0);
    col += vec3(0.10, 0.04, 0.14) * pow(n, 3.0);

    return col;
}

vec3 bbColor(float t) {
    t = clamp(t, 0.0, 2.5);
    vec3 lo = vec3(1.0, 0.18, 0.0);
    vec3 mi = vec3(1.0, 0.55, 0.12);
    vec3 hi = vec3(1.0, 0.93, 0.82);
    vec3 hot = vec3(0.65, 0.82, 1.0);
    vec3 c = mix(lo, mi, smoothstep(0.0, 0.3, t));
    c = mix(c, hi, smoothstep(0.3, 0.8, t));
    return mix(c, hot, smoothstep(0.8, 1.8, t));
}

vec4 shadeDisk(vec3 hit, vec3 vel, float t) {
    float r = length(hit.xz);
    if (r < DISK_IN * 0.5 || r > DISK_OUT * 1.05) return vec4(0.0);

    float xr = ISCO / r;
    float tProfile = pow(ISCO / r, 0.75) * pow(max(0.001, 1.0 - sqrt(xr)), 0.25);
    float gRedshift = sqrt(max(0.01, 1.0 - RS / r));
    tProfile *= gRedshift;

    float phi = atan(hit.z, hit.x);
    float lr = log2(max(r, 0.1));

    float keplerOmega = sqrt(0.5 * RS / (r * r * r));
    float baseOmega = 0.04;
    float omega = max(keplerOmega, baseOmega) * 10.0;
    float rotAngle = t * omega;
    float ca = cos(rotAngle), sa = sin(rotAngle);
    vec2 rotXZ = vec2(hit.x * ca - hit.z * sa, hit.x * sa + hit.z * ca);

    float turb = fbm(rotXZ * 1.2 + vec2(lr * 3.0));
    turb = 0.25 + 0.75 * turb;

    float timeShift = t * 0.15;
    float detail = gNoise(rotXZ * 3.5 + vec2(100.0 + timeShift, timeShift * 0.7));
    turb *= 0.7 + 0.3 * detail;

    float ringPhase1 = sin(r * 10.0 + rotAngle * r * 0.3) * 0.5 + 0.5;
    float ringPhase2 = sin(r * 20.0 - rotAngle * r * 0.15) * 0.5 + 0.5;
    float rings = ringPhase1 * 0.55 + ringPhase2 * 0.45;
    rings = 0.5 + 0.5 * rings;
    turb *= rings;

    float orbSpeed = sqrt(0.5 * RS / max(r, DISK_IN));
    vec3 orbDir = normalize(vec3(-hit.z, 0.0, hit.x));
    float dopplerFactor = 1.0 + 2.0 * dot(normalize(vel), orbDir) * orbSpeed;
    dopplerFactor = max(0.15, dopplerFactor);
    float dopplerBoost = dopplerFactor * dopplerFactor * dopplerFactor;

    float I = tProfile * turb * 6.0;

    float innerFade = smoothstep(DISK_IN * 0.7, DISK_IN * 1.2, r);
    float iscoFade = 0.35 + 0.65 * smoothstep(ISCO * 0.85, ISCO * 1.2, r);
    float outerFade = 1.0 - smoothstep(DISK_OUT * 0.55, DISK_OUT, r);
    I *= innerFade * iscoFade * outerFade;

    float colorTemp = tProfile * pow(dopplerFactor, 1.8) * 1.2;
    vec3 col = bbColor(colorTemp) * I * dopplerBoost;

    if (CHROMATIC > 0.01) {
        float spectralR = (r - DISK_IN) / (DISK_OUT - DISK_IN);
        float ringP = ringPhase1;
        float hue = spectralR * 0.8 + ringP * 0.4;

        vec3 spectrum;
        spectrum.r = (1.0 - smoothstep(0.0, 0.35, hue))
                   + smoothstep(0.25, 0.45, hue) * (1.0 - smoothstep(0.55, 0.7, hue)) * 0.7
                   + smoothstep(0.85, 1.1, hue) * 0.4;
        spectrum.g = smoothstep(0.15, 0.4, hue) * (1.0 - smoothstep(0.7, 0.95, hue));
        spectrum.b = smoothstep(0.5, 0.8, hue)
                   + smoothstep(0.85, 1.1, hue) * 0.3;
        spectrum = max(spectrum, 0.05);

        float luma = dot(col, vec3(0.3, 0.5, 0.2));
        vec3 chromaCol = spectrum * luma * 2.0;
        col = mix(col, chromaCol, CHROMATIC * 0.75);
    }

    float alpha = clamp(I * 1.3, 0.0, 0.96);
    return vec4(col, alpha);
}

void main() {
    vec2 fc = vec2(v_coords.x, 1.0 - v_coords.y) * size;
    vec2 ctr = vec2(0.5) * size;
    vec2 uv = (fc - ctr) / size.x;

    float camR = 28.0;
    float orbit = u_time * 0.055 * ROTATION_SPEED;
    float tilt = 0.25 + TILT_OFFSET;

    vec3 eye = vec3(
        camR * cos(orbit) * cos(tilt),
        camR * sin(tilt),
        camR * sin(orbit) * cos(tilt)
    );

    vec3 fwd = normalize(-eye);
    vec3 rt = normalize(cross(fwd, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(rt, fwd);

    float cr = cos(ROLL), sr = sin(ROLL);
    vec3 rr = cr * rt + sr * up;
    vec3 ru = -sr * rt + cr * up;

    vec3 rd = normalize(fwd + uv.x * rr + uv.y * ru);

    if (STARS_ONLY > 0.5) {
        vec3 s = starField(rd);
        gl_FragColor = vec4(pow(s, vec3(0.45)), 1.0);
        return;
    }

    vec3 pos = eye;
    vec3 vel = rd;

    vec3 Lvec = cross(pos, vel);
    float L2 = dot(Lvec, Lvec);

    vec4 diskAccum = vec4(0.0);
    vec3 glow = vec3(0.0);
    bool absorbed = false;
    int diskCrossings = 0;
    float minR = 1000.0;

    float gravCoeff = -1.5 * RS * L2;

    for (int i = 0; i < 200; i++) {
        float r = length(pos);

        float h = 0.16 * clamp(r - 0.4 * RS, 0.06, 3.5);

        float invR2 = 1.0 / (r * r);
        float invR5 = invR2 * invR2 / r;
        vec3 acc = (gravCoeff * invR5) * pos;

        vec3 p1 = pos + vel * h + 0.5 * acc * h * h;
        float r1 = length(p1);
        float invR12 = 1.0 / (r1 * r1);
        float invR15 = invR12 * invR12 / r1;
        vec3 acc1 = (gravCoeff * invR15) * p1;
        vec3 v1 = vel + 0.5 * (acc + acc1) * h;

        minR = min(minR, r1);

        if (pos.y * p1.y < 0.0 && diskAccum.a < 0.97) {
            float tHit = pos.y / (pos.y - p1.y);
            vec3 hit = mix(pos, p1, tHit);
            vec4 dc = shadeDisk(hit, vel, u_time * ROTATION_SPEED);
            dc.rgb *= DISK_INTENSITY;
            if (diskCrossings >= 2) {
                dc.rgb *= 0.15;
                dc.a *= 0.15;
            }
            diskAccum.rgb += dc.rgb * dc.a * (1.0 - diskAccum.a);
            diskAccum.a += dc.a * (1.0 - diskAccum.a);
            float diskBright = dot(dc.rgb, vec3(0.3, 0.5, 0.2)) * dc.a;
            glow += dc.rgb * 0.04 * max(diskBright - 0.3, 0.0);
            diskCrossings++;
        }

        if (r1 < 6.0) {
            float pDist = abs(r1 - 1.5 * RS);
            float psGlow = 1.0 / (1.0 + pDist * pDist * 20.0) * h * 0.001 / max(r1 * r1, 0.2);
            glow += vec3(0.8, 0.6, 0.35) * psGlow;

            float hzGlow = exp(-(r1 - RS) * 3.5) * h * 0.003;
            glow += vec3(0.5, 0.25, 0.08) * max(hzGlow, 0.0);
        }

        if (r1 < RS * 0.35) { absorbed = true; break; }
        if (r1 > 25.0 && r1 > r) break;
        if (r1 > 55.0) break;

        pos = p1;
        vel = v1;
    }

    vec3 col = vec3(0.0);
    if (!absorbed) {
        col = starField(normalize(vel));
    }
    col = col * (1.0 - diskAccum.a) + diskAccum.rgb;

    float ringDist = abs(minR - 1.5 * RS);
    float chromo = CHROMATIC;

    float baseChroma = 0.1 + 0.5 * chromo;
    float spread = 0.08 + 0.18 * chromo;
    float falloff = 20.0 + 15.0 * (1.0 - chromo);
    float rRing = exp(-(ringDist + spread) * (ringDist + spread) * falloff);
    float bRing = exp(-(ringDist - spread) * (ringDist - spread) * falloff);
    col.r += rRing * 0.3 * baseChroma;
    col.b += bRing * 0.35 * baseChroma;

    col += glow;

    col *= 1.4;
    vec3 a = col * (col + 0.0245786) - 0.000090537;
    vec3 b = col * (0.983729 * col + 0.4329510) + 0.238081;
    col = a / b;

    col = smoothstep(0.0, 1.0, col);
    col = pow(max(col, 0.0), vec3(0.92));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
