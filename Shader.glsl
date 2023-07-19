# version 120

uniform vec2 asp_rat;
uniform float sy;
uniform vec3 ro;
uniform vec3 mo;
uniform float time;
uniform vec2 u_mouse;
uniform float alpha;
uniform float ms;
uniform float tx;
uniform float tick;
//uniform float rand;
uniform float rand1;
uniform float rand2;
uniform float rand3;
uniform int mode;
uniform bool trace;
uniform bool heavy;

// whatever direction/transformation should be applied to the rayDirection before normalizing it
uniform vec3 Camera_dir;

// Quality
#define MAX_STEPS (1000)
#define MAX_DIST (1000.)
#define SURFACE_DIST (0.01)

// Constants
#define PHI (1.618033988749895)
#define PI (3.14159265)

#define fGDF(v) d = max(d, abs(dot(p, v)));
#define fD(v) d = min(d, v)
#define fDm(v) d = max(d, v)
#define fC(c, alpha) col *= c, dir = reflect(dir, mix(normal, rand, alpha*alpha)); if (getDist(point + SURFACE_DIST * 3. * dir) < SURFACE_DIST) break; point += SURFACE_DIST * 2. * dir;
#define fiD(v, c, alpha) if (v < SURFACE_DIST){ fC(c, alpha); continue; }

// Light

#define lightPos vec3(8, 3.2, 20)
#define Light2(point) Dodecahedron(point - vec3(4.5, 0.25, 6), 1.0, tick*5.)
#define Light(point) Sphere(point - lightPos, 0.5)

float random(vec3 point){
    return fract(sin(dot(point.zx + point.y * time, vec2(12.9898 * time, 78.233 / time))) * (43758.5453123 + tick)) / 10.;
}

mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}
float smoothUnion(float d1, float d2, float k){
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float Sphere(vec3 point, float r){ return length(point) - r; }
float Plane(vec3 p, vec3 n){
    return dot(p, n);
}

float Tetrahedron(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    p /= scale;
    return max(abs(p.y) - 1., max(abs(p.x) * 0.866025 + p.z / 2., -p.z) - 0.39 * abs(1. - p.y)) * scale;
}
float Cube(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    p /= scale;
    vec3 q = abs(p) - 1.0;
    return (length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.)) * scale;
}
float StellatedOctahedron(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    p /= scale;
    vec3 p2 = p;
    p2.zy *= rot(PI);
    return min(Tetrahedron(p - vec3(0., 1., 0.), 1., 0.), Tetrahedron(p2, 1., 0.)) * scale;
}
float Octahedron_c(vec3 p, float scale, float angle){
    p /= scale;
    vec3 p2 = p;
    p2.zy *= rot(PI);
    return max(Tetrahedron(p - vec3(0., 1., 0.), 1.0, 0.), Tetrahedron(p2, 1.0, 0.)) * scale;
}
float Octahedron(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    p = abs(p) / scale;
    float m = p.x + p.y + p.z - 1.0;
    vec3 q;
    if (3.0 * p.x < m) q = p.xyz;
    else if (3.0 * p.y < m) q = p.yzx;
    else if (3.0 * p.z < m) q = p.zxy;
    else return m * 0.57735027;
    
    float k = clamp(0.5 * (q.z - q.y + 1.0), 0.0, 1.0);
    return length(vec3(q.x, q.y - 1.0 + k, q.z - k)) * scale;
}
float Dodecahedron(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    p /= scale;
    float d = 0.;

    d = max(d, abs(dot(p, normalize(vec3(0, PHI, 1)))));
    d = max(d, abs(dot(p, normalize(vec3(0, -PHI, 1)))));
    d = max(d, abs(dot(p, normalize(vec3(1, 0, PHI)))));
    d = max(d, abs(dot(p, normalize(vec3(-1, 0, PHI)))));
    d = max(d, abs(dot(p, normalize(vec3(PHI, 1, 0)))));
    d = max(d, abs(dot(p, normalize(vec3(-PHI, 1, 0)))));
    
    return d * scale - scale;
}
float Icosahedron(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    p /= scale;
    float d = 0.;
    
    d = max(d, abs(dot(p, normalize(vec3(1, 1, 1 )))));
    d = max(d, abs(dot(p, normalize(vec3(-1, 1, 1)))));
    d = max(d, abs(dot(p, normalize(vec3(1, -1, 1)))));
    d = max(d, abs(dot(p, normalize(vec3(1, 1, -1)))));
    d = max(d, abs(dot(p, normalize(vec3(0, 1, PHI + 1.)))));
    d = max(d, abs(dot(p, normalize(vec3(0, -1, PHI + 1.)))));
    d = max(d, abs(dot(p, normalize(vec3(PHI + 1., 0, 1)))));
    d = max(d, abs(dot(p, normalize(vec3(-PHI - 1., 0, 1)))));
    d = max(d, abs(dot(p, normalize(vec3(1, PHI + 1., 0)))));
    d = max(d, abs(dot(p, normalize(vec3(-1, PHI + 1., 0)))));
    
    return d * scale - scale;
}

float TruncatedCube(vec3 point, float scale, float angle){
    point.xz *= rot(angle);
    return max(Cube(point, scale, 0.), Octahedron(point, scale * 2.375, 0.));
}
float Rhombicuboctahedron(vec3 point, float scale, float angle){
    point.xz *= rot(angle);
    float d = Cube(point, scale, 0.);
    
    vec3 p = point;
    p.xy *= rot(3.1415926 / 4.);
    fDm(Cube(p, scale, 0.));
    
    p = point;
    p.yz *= rot(3.1415926 / 4.);
    fDm(Cube(p, scale, 0.));
    
    p = point;
    p.zx *= rot(3.1415926 / 4.);
    fDm(Cube(p, scale, 0.));
    
    return max(d, Octahedron(point, scale * 1.825, 0.));
}
float StellatedRhombicuboctahedron(vec3 point, float scale, float angle){
    point.xz *= rot(angle);
    float d = Cube(point, scale, 0.);
    
    vec3 p = point;
    p.xy *= rot(3.1415926 / 4.);
    fD(Cube(p, scale, 0.));
    
    p = point;
    p.yz *= rot(3.1415926 / 4.);
    fD(Cube(p, scale, 0.));
    
    p = point;
    p.zx *= rot(3.1415926 / 4.);
    fD(Cube(p, scale, 0.));
    
    return min(d, Octahedron(point, scale * 1.825, 0.));
}
float StellatedCuboctahedron(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    return min(Octahedron(p, scale, 0.), Cube(p, scale / 2., 0.)) * scale;
}
float Cuboctahedron(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    return max(Octahedron(p, scale, 0.), Cube(p, scale / 2., 0.));
}

// 0.7265 - tg(36)

float FiveCubes(vec3 point, float scale, float angle){
    point /= scale;
    point.xz *= rot(angle);

    float phi = 0.7265;
    float d = Cube(point, phi, 0.);
    vec3 p = point + vec3(-phi, -phi, phi);
    
    p.xz *= rot(0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(0.36);
    d = min(d, Cube(p - vec3(-phi, -phi, phi), phi, 0.));

    p = point + vec3(phi, -phi, phi);
    p.xz *= rot(-0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(-0.36);
    d = min(d, Cube(p - vec3(phi, -phi, phi), phi, 0.));

    point.xz *= rot(PI);

    p = point + vec3(-phi, -phi, phi);
    p.xz *= rot(0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(0.36);
    d = min(d, Cube(p - vec3(-phi, -phi, phi), phi, 0.));

    p = point + vec3(phi, -phi, phi);
    p.xz *= rot(-0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(-0.36);
    d = min(d, Cube(p - vec3(phi, -phi, phi), phi, 0.));
    
    return d * scale;
}
float RhombicTriacontahedron(vec3 point, float scale, float angle){
    point /= scale;
    point.xz *= rot(angle);
    
    float phi = 0.7265;
    float d = Cube(point, phi, 0.);
    
    vec3 p = point + vec3(-phi, -phi, phi);
    p.xz *= rot(0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(0.36);
    d = max(d, Cube(p - vec3(-phi, -phi, phi), phi, 0.));
    
    p = point + vec3(phi, -phi, phi);
    p.xz *= rot(-0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(-0.36);
    d = max(d, Cube(p - vec3(phi, -phi, phi), phi, 0.));
    
    point.xz *= rot(PI);
    
    p = point + vec3(-phi, -phi, phi);
    p.xz *= rot(0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(0.36);
    d = max(d, Cube(p - vec3(-phi, -phi, phi), phi, 0.));
    
    p = point + vec3(phi, -phi, phi);
    p.xz *= rot(-0.365);
    p.yz *= rot(-0.52);
    p.xy *= rot(-0.36);
    d = max(d, Cube(p - vec3(phi, -phi, phi), phi, 0.));
    
    return d * scale;
}
float StellatedIcosaDodecahedron(vec3 point, float scale, float angle){
    point.xz *= rot(angle);
    return min(Dodecahedron(point, scale, 0.), Icosahedron(point, 1.095 * scale, 0.));
}
float IcosaDodecahedron(vec3 point, float scale, float angle){
    point.xz *= rot(angle);
    return max(Dodecahedron(point, scale, 0.), Icosahedron(point, 1.095 * scale, 0.));
}
float ZolarsFractal(vec3 point, float angle){
    point.xz *= rot(angle);
    
    float d = Cube(point, 1., 0.);
    fD(Cube(point - vec3(1.5, 0.5, 0.5), 0.5, 0.));
    fD(Cube(point - vec3(0.5, 0.5, -1.5), 0.5, 0.));fD(Cube(point - vec3(-1.5, -0.5, -0.5), 0.5, 0.));fD(Cube(point - vec3(-0.5, -0.5, 1.5), 0.5, 0.));fD(Cube(point - vec3(-0.5, 1.5, 0.5), 0.5, 0.));fD(Cube(point - vec3(0.5, -1.5, -0.5), 0.5, 0.));
    
    //    fD(Cube(point - vec3(2.25, 0.75, 0.75), 0.25));fD(Cube(point - vec3(1.25, 0.75, -1.25), 0.25));fD(Cube(point - vec3(0.25, -0.25, 1.75), 0.25));fD(Cube(point - vec3(0.25, 1.75, 0.75), 0.25));fD(Cube(point - vec3(1.25, -1.25, -0.25), 0.25));
    //    fD(Cube(point - vec3(1.75, 0.75, -0.25), 0.25));fD(Cube(point - vec3(0.75, 0.75, -2.25), 0.25));fD(Cube(point - vec3(-1.25, -0.25, -1.25), 0.25));fD(Cube(point - vec3(-0.25, 1.75, -0.25), 0.25));fD(Cube(point - vec3(0.75, -1.25, -1.25), 0.25));
    //    fD(Cube(point - vec3(-0.25, 0.25, -1.75), 0.25));fD(Cube(point - vec3(-2.25, -0.75, -0.75), 0.25));fD(Cube(point - vec3(-1.25, -0.75, 1.25), 0.25));fD(Cube(point - vec3(-1.25, 1.25, 0.25), 0.25));fD(Cube(point - vec3(-0.25, -1.75, -0.75), 0.25));
    //    fD(Cube(point - vec3(1.25, 0.25, 1.25), 0.25));fD(Cube(point - vec3(-1.75, -0.75, 0.25), 0.25));fD(Cube(point - vec3(-0.75, -0.75, 2.25), 0.25));fD(Cube(point - vec3(-0.75, 1.25, 1.25), 0.25));fD(Cube(point - vec3(0.25, -1.75, 0.25), 0.25));
    //    fD(Cube(point - vec3(1.25, 1.25, 0.75), 0.25));fD(Cube(point - vec3(0.25, 1.25, -1.25), 0.25));fD(Cube(point - vec3(-1.75, 0.25, -0.25), 0.25));fD(Cube(point - vec3(-0.75, 0.25, 1.75), 0.25));fD(Cube(point - vec3(-0.75, 2.25, 0.75), 0.25));
    //    fD(Cube(point - vec3(1.75, -0.25, 0.25), 0.25));fD(Cube(point - vec3(0.75, -0.25, -1.75), 0.25));fD(Cube(point - vec3(-1.25, -1.25, -0.75), 0.25));fD(Cube(point - vec3(-0.25, -1.25, 1.25), 0.25));fD(Cube(point - vec3(0.75, -2.25, -0.75), 0.25));
    
    return d;
}
float FiveOctahedrons(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    
    float d = Octahedron(p, scale, 0.);
    
    for (int i = 0; i < 5; i++){
        p.xz *= rot(0.355); p.zy *= rot(-0.515); p.yx *= rot(-1.21);
        fD(Octahedron(p, scale, 0.));
    }

    return d;
}
float FiveTetrahedrons(vec3 p, float scale, float angle){
    p.xz *= rot(angle);
    
    float d = Tetrahedron(p, scale, 0.);
    
    for (int i = 0; i < 5; i++){
        p.xz *= rot(mo.x); p.zy *= rot(mo.y); p.yx *= rot(mo.z);
        fD(Tetrahedron(p, scale, 0.));
    }
    
    return d;
}

float Cone(vec3 p, vec2 c, float h){
    float q = length(p.xz);
    return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}
float Heart(vec3 point){
    float md = smoothUnion(Sphere(point - vec3(0.5, 1.5, 6), 1.), Sphere(point - vec3(1.5, 1.5, 6), 1.), 0.1);
    point -= vec3(1, -0.5, 6);
    point.zy *= rot(PI);
    point.x *= 0.63;
    return smoothUnion(md, Cone(point, vec2(1.1, 0.5), 1.5), 0.2);
}
float Cylinder( vec3 p, float h, float r ){
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float Candle(vec3 point){
    float d = Cylinder(point - vec3(-1, -0.75, 2), 0.223, 0.874);
    fD(Cylinder(point - vec3(-1, -0.527, 2), 0.063, 0.774));
    fD(Cylinder(point - vec3(-1, 0.375, 2), 1.5, 0.1625) + random(point) / 10.);
    fD(Cylinder(point - vec3(-1, 1.875, 2), 0.15, 0.0173));

    return d;
}

float cubecut(vec3 point){
    float d = max(Cube(point - vec3(8, 0, 30), 1., 0.), -Sphere(point - vec3(7.5, 0.25, 29.5), 1.));
    
    return d;
}

// Calculation next step

float getDist(vec3 point){
    float d = Plane(point - vec3(0, -1, 0), vec3(0., 1., 0.));
    
    if (trace) fD(Light(point));

    fD(Cube(point - vec3(4.4, 2, 29), 4., PI / 12.));
    
    return d;
}

// Normal to a surface

vec3 randomOnSphere(vec3 point){
    vec2 epsilon = vec2(SURFACE_DIST, 0);
    vec3 normal = vec3(
                    random(point) - random(point.zyx),
                    random(point.yxz) - random(point.zxy),
                    random(point.xzy) - random(point.yzx)
                );
    
    return normal;
}

vec3 getNormal(vec3 point){
    vec2 epsilon = vec2(SURFACE_DIST, 0);
    vec3 normal = vec3(
                       getDist(point + epsilon.xyy) - getDist(point - epsilon.xyy),
                       getDist(point + epsilon.yxy) - getDist(point - epsilon.yxy),
                       getDist(point + epsilon.yyx) - getDist(point - epsilon.yyx)
                       );
    
    return normalize(normal);
}

vec3 rayMarch(vec3 origin, vec3 o_dir){
    float totalDist = 0.;
    float minLightDist = MAX_DIST;
    int r = 0;

//    vec3 col = vec3(0.786, 0.633, 0.335);
    vec3 col = vec3(1);
//    vec3 col = vec3(0.63, 0.36, 0.1);
    vec3 dir = o_dir;
    vec3 point = origin;

    for (int i = 0; i <= MAX_STEPS; i++){
        float dist = getDist(point);
        totalDist += dist;
        point += dist * dir;

        minLightDist = min(Light(point), minLightDist);

        if (Light(point) < SURFACE_DIST) break;
        if (dist < SURFACE_DIST){
            vec3 rand = randomOnSphere(point), normal = getNormal(point);
            rand = normalize(rand * (dot(rand, normal)));

            fiD(Cube(point - vec3(4.4, 2, 29), 4., PI / 12.), vec3(0.5), 0.2);
            
            fC(vec3(0.5), 0.9);
            
            r++;
        }

//        if (r > 8 || i == MAX_STEPS || totalDist > MAX_DIST){ col *= 0.; break; }
        if (totalDist > MAX_DIST) break;
    }
    
    // Luminance calculating
//    col /= totalDist * totalDist;
    col /= minLightDist;
    col /= Light(point);

    return col;
}

float rayMarch_s(vec3 origin, vec3 dir){
    float totalDist = 0.;
    
    for (int i = 0; i < MAX_STEPS; i++){
        vec3 point = origin + totalDist * dir;
        float dist = getDist(point);
        totalDist += dist;
        
        if (totalDist > MAX_DIST || dist < SURFACE_DIST)
            break;
    }

    return totalDist;
}

vec3 getLight(vec3 point, vec3 origin){
    vec3 pointToLight = lightPos - point;
    vec3 lightVec = normalize(pointToLight);
    vec3 normal = getNormal(point);

    float distSqPtLght = dot(pointToLight, pointToLight);

    const vec3  diffColor = vec3(1, 1, 1);
    const vec3  specColor = vec3(1, 1, 1);
    const float specPower = 30.0;

    vec3 v2 = normalize(origin - point);
    vec3 r = reflect ( -v2, normal );
    vec3 diff = diffColor * max ( dot ( normal, lightVec ), 0.0 );
    vec3 spec = specColor * pow ( max ( dot ( lightVec, r ), 0.0 ), specPower );

    vec3 light = diff + spec;

    float dist = rayMarch_s(point + 2. * SURFACE_DIST * normal, lightVec);
    if (dist*dist < distSqPtLght) light *= 0.5;

    return light;
}

void main(){
    vec2 uv = gl_FragCoord.xy / sy - asp_rat;
    
    vec3 rayDirection = normalize(vec3(uv, asp_rat * 4.));
    rayDirection.zy *= rot(u_mouse.y);
    rayDirection.xz *= rot(u_mouse.x);
    vec3 col = vec3(1.0);
    
    if (!trace){
        // realtime ray marching
        float dist = rayMarch_s(ro, rayDirection);
        col = vec3(getLight(ro + rayDirection * dist, ro));
    }
    else {
        // raytrace ray marching
        col = rayMarch(ro, rayDirection);
        col *= col;
//        col *= 500.;
        float white = 100.0;
        col *= white * 16.;
        col = (col * (1.0 + col / white / white)) / (1.0 + col);
    }

    gl_FragColor = vec4(col, alpha);
}
