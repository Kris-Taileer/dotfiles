#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec2 v_coords;
uniform vec2 size;
uniform float u_time;

#define MAX_STEPS 100
#define MAX_DIST 30.0
#define SURF_DIST 0.0008
#define WIRE_R 0.025

mat2 rot2(float a){
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 hsv2rgb(vec3 c){
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    vec3 rgb = clamp(p - 1.0, 0.0, 1.0);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

float sdSegment(vec3 p, vec3 a, vec3 b){
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdWirePyramid(vec3 p){
    vec3 apex = vec3(0.0, 1.0, 0.0);
    vec3 b0 = vec3(-1.0, -1.0, -1.0);
    vec3 b1 = vec3( 1.0, -1.0, -1.0);
    vec3 b2 = vec3( 1.0, -1.0,  1.0);
    vec3 b3 = vec3(-1.0, -1.0,  1.0);

    float d = sdSegment(p, b0, b1);
    d = min(d, sdSegment(p, b1, b2));
    d = min(d, sdSegment(p, b2, b3));
    d = min(d, sdSegment(p, b3, b0));
    d = min(d, sdSegment(p, apex, b0));
    d = min(d, sdSegment(p, apex, b1));
    d = min(d, sdSegment(p, apex, b2));
    d = min(d, sdSegment(p, apex, b3));
    return d - WIRE_R;
}

float map(vec3 p){
    vec3 q = p;
    q.xz = rot2(u_time * 0.6) * q.xz;
    q.yz = rot2(0.4) * q.yz;
    return sdWirePyramid(q);
}

vec3 getNormal(vec3 p){
    vec2 e = vec2(0.001, 0.0);
    float d = map(p);
    vec3 n = d - vec3(
        map(p - e.xyy),
        map(p - e.yxy),
        map(p - e.yyx)
    );
    return normalize(n);
}

void main(void){
    vec2 uv = (2.0 * v_coords * size - size) / min(size.x, size.y);

    vec3 ro = vec3(0.0, 0.6, -4.0);
    vec3 ta = vec3(0.0, 0.0, 0.0);
    vec3 fwd = normalize(ta - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), fwd));
    vec3 up = cross(fwd, right);
    vec3 rd = normalize(fwd * 1.6 + uv.x * right + uv.y * up);

    float t = 0.0;
    float glow = 0.0;
    float hitT = -1.0;

    for (int i = 0; i < MAX_STEPS; i++){
        vec3 p = ro + rd * t;
        float d = map(p);
        glow += 0.0015 / (0.001 + d * d);
        if (d < SURF_DIST){
            hitT = t;
            break;
        }
        t += d;
        if (t > MAX_DIST) break;
    }

    vec3 col = vec3(0.0);

    if (hitT > 0.0){
        vec3 p = ro + rd * hitT;
        vec3 n = getNormal(p);
        vec3 lightPos = vec3(2.0, 3.0, -2.0);
        vec3 l = normalize(lightPos - p);
        float diff = max(dot(n, l), 0.0);
        float fres = pow(1.0 - max(dot(n, -rd), 0.0), 2.0);

        float hue = fract(u_time * 0.15 + p.y * 0.12);
        vec3 base = hsv2rgb(vec3(hue, 0.85, 1.0));

        col = base * (0.4 + 0.8 * diff) + base * fres * 0.6;
    }

    vec3 glowHue = hsv2rgb(vec3(fract(u_time * 0.15), 0.85, 1.0));
    col += glowHue * glow;

    col = col / (1.0 + col);
    col = pow(col, vec3(0.4545));
    gl_FragColor = vec4(col, 1.0);
}
