# version 120

uniform vec2 resolution;
uniform vec3 rayOrigin;
uniform vec2 u_mouse;
uniform float time;
uniform float tick;
uniform float rand0;
uniform float rand1;
uniform float rand2;
uniform float alpha;

uniform sampler2D u_sample;
uniform float u_sample_part;
uniform int samples;

// Limits and quality settings

#define MAX_DIST (100.)
#define MAX_STEPS (100)
#define MAX_REFRACTIONS 8
vec3 light = normalize(vec3(-0.5, 0.75, -1.0));
float seed;

#define PHI (1.618033988749895)
#define PI (3.14159265)
#define fP(Primitive, PrimitiveN, PrimitiveC) it = Primitive; if(it.x > 0.0 && it.x < minIt.x) minIt = it, n = PrimitiveN, col = PrimitiveC;
#define fL(Primitive, PrimitiveC) it = Primitive; if(it.x > 0.0 && it.x < minIt.x) minIt = it, col = PrimitiveC;

float random(vec3 point){
    return fract(sin(dot(point.zx * seed + point.y * rand0, vec2(12.9898 * seed, 78.233 / time))) * (43758.5453123 + rand2)) / 10.;
}
vec3 randomOnSphere(vec3 point){
    vec2 epsilon = vec2(0.001, 0);
    vec3 normal = vec3(
                    random(point) - random(point.zyx),
                    random(point.yxz) - random(point.zxy),
                    random(point.xzy) - random(point.yzx)
                );
    
    return normal;
}

mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 getSky(vec3 rd) {
    vec3 col = vec3(0.3, 0.6, 1.0);
    vec3 sun = vec3(0.95, 0.9, 1.0);
    sun *= max(0.0, pow(dot(rd, light), 256.0));
    col *= max(0.0, dot(light, vec3(0.0, 0.0, -1.0)));
    return clamp(sun + col * 0.01, 0.0, 1.0);
}

vec2 Sphere(in vec3 ro, in vec3 rd, in float ra){
    float b = dot(ro, rd);
    float c = dot (ro, ro) - ra * ra;
    float h = b * b - c;

    if(h < 0.0) return vec2(-1.0);

    h = sqrt(h);

    return vec2(-b - h, -b + h);
}
vec2 Box(in vec3 ro, in vec3 rd, in vec3 rad, out vec3 oN){
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if(tN > tF || tF < 0.0) return vec2(-1.0);
    oN = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    return vec2(tN, tF);
}
float Plane(in vec3 ro, in vec3 rd, in vec4 p) {
    return -(dot(ro, p.xyz) + p.w) / dot(rd, p.xyz);
}

vec4 castRay(inout vec3 ro, inout vec3 rd){
    vec4 col;
    vec2 minIt = vec2(MAX_DIST), it;
    vec3 n, boxN, boxN2, spherePos = vec3(-1.3, 0, 5), boxPos = vec3(2, 0, 5), planeNormal = vec3(0, 1, 0);
    
    fL(Box(ro - vec3(0, 6, 3), rd, vec3(1, 0.001, 1), boxN), vec4(vec3(1), -2));

    fP(Sphere(ro - spherePos, rd, 1.0), normalize(ro + rd * it.x - spherePos), vec4(1, 0.1, 0.1, 0.));
    fL(Sphere(ro - vec3(-0.5, -0.8, 4.5), rd, 0.2), vec4(0.01 , 0.8, 0.02, -2));
    fP(Sphere(ro - vec3(-2.1, -0.4, 3.6), rd, 0.6), normalize(ro + rd * it.x - vec3(-2.1, -0.4, 3.6)), vec4(vec3(0.1, 0.9, 0.2), 1));
    fP(Sphere(ro - vec3(0.2, -0.5, 3), rd, 0.5), normalize(ro + rd * it.x - vec3(0.2, -0.5, 3)), vec4(vec3(1), -0.5));
    fL(Sphere(ro - vec3(0.8, -0.6, 6.8), rd, 0.4), vec4(vec3(0.392, 0.254, 0), -2));
    fP(Box(ro - vec3(1.6, 1.4, 5.8), rd, vec3(0.4), boxN2), boxN2, vec4(vec3(0.392, 0.254, 0.1), 1));
    fP(Box(ro - boxPos, rd, vec3(1), boxN), boxN, vec4(0.2, 0.2, 0.8, 0.25));
    fP(vec2(Plane(ro, rd, vec4(planeNormal, 1))), planeNormal, vec4(vec3(0.9), 1));
    
    fP(vec2(Plane(ro - vec3(2.5, 0, 0), rd, vec4(-1, 0, 0, 1))), vec3(-1, 0, 0), vec4(vec3(0.1, 0.9, 0.1), 1));
    fP(vec2(Plane(ro - vec3(-2.5, 0, 0), rd, vec4(1, 0, 0, 1))), vec3(1, 0, 0), vec4(vec3(0.9, 0.1, 0.1), 1));
    fP(vec2(Plane(ro - vec3(0, 0, 8), rd, vec4(0, 0, -1, 1))), vec3(0, 0, -1), vec4(vec3(0.9), 1));
    fP(vec2(Plane(ro - vec3(0, 5, 0), rd, vec4(0, -1, 0, 1))), vec3(0, -1, 0), vec4(vec3(0.9), 1));

//    if (minIt.x == MAX_DIST) return vec4(vec3(0.8, 0.96, 1), -2);
    if (minIt.x == MAX_DIST) return vec4(getSky(rd), -2);
    if (col.a == -2.) return col;
    
    vec3 reflected = reflect(rd, n);
    if(col.a < 0.0) {
        float fresnel = 1.0 - abs(dot(-rd, n));
        float rnd = random(ro);
        rnd -= int(rnd);
        if(abs(rnd) + 0.25 < fresnel * fresnel) {
            rd = reflected;
            return col;
        }
        ro += rd * (minIt.y + 0.001);
        rd = refract(rd, n, 1.0 / (1.0 - col.a));
        return col;
    }
    
    ro += rd * (minIt.x - 0.001);
    vec3 rand = randomOnSphere(ro);
    rand = normalize(rand * dot(rand, n));
    rd = mix(reflect(rd, n), rand, col.a * col.a);
//    rd = reflect(rd, n);
    
    return col;
}

vec3 traceRay(vec3 ro, vec3 rd){
    vec3 col = vec3(1);
    for(int i = 0; i < MAX_REFRACTIONS; i++){
        vec4 refCol = castRay(ro, rd);
        col *= refCol.rgb;
        if (refCol.a == -2.) return col;
    }
    return vec3(0);
}

void main(){
    vec2 uv = gl_FragCoord.xy / resolution.y - vec2(resolution.x / resolution.y / 2., 0.5);
    seed = time * uv.x + uv.y;

    vec3 rayDirection = normalize(vec3(uv, 1.));
    rayDirection.zy *= rot(u_mouse.y);
    rayDirection.xz *= rot(u_mouse.x);
    
    vec3 col = vec3(0);// = traceRay(rayOrigin, rayDirection);
    
//    int samples = 16;
    for(int i = 0; i < samples; i++){
        col += traceRay(rayOrigin, rayDirection);
        seed = random(rayDirection * seed);
    }
    col = col / float(samples);
    
    float white = 20.0;
    col *= white * 16.0;
    col = (col * (1.0 + col / white / white)) / (1.0 + col);
    
//    col *= 2.;
    
//    vec3 sampleCol = texture(u_sample, gl_TexCoord[0].xy).rgb;
//    col = mix(sampleCol, col, u_sample_part);
    
    gl_FragColor = vec4(col, alpha);
}
