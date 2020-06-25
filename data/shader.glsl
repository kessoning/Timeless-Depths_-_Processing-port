precision mediump float;

#define MAX_STEPS 100
#define MAX_DIST 8.
#define SURF_DIST .001
#define GYROID_DETAILS 6

uniform vec2 iResolution;
uniform float iTime;

uniform vec3 rocksColor = vec3(0.4, 0.4, 1.0);
uniform vec3 waterColor = vec3(0.05, 0.18, 0.38);
uniform float size = 2.345;
uniform bool wideangle = true;
uniform float speed = 1.0;

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdGyroid(vec3 p, float s, float t, float b) {
    vec3 st = p * s;
    
    float lx = 1.0 + ((sin(iTime * 0.0576 * speed) * 0.5) + 0.5) * 0.25;    
    float ly = 1.0 + ((cos(iTime * 0.0565 * speed) * 0.5) + 0.5) * 0.25;
    
    float ls = max(lx, ly);
    
    return abs(dot(sin(st * lx), cos(st.zxy * ly)) - b) / (s * ls) - t;
}

vec3 transform(vec3 p) {
    p.xy *= rotate(p.z * 0.1);
    p.z += iTime * 0.1;
    p.y -= 0.3;
    return p;
}

float GetDist(vec3 p) {
    p = transform(p);
        
    float s = 10.798;
    float t = 0.03;
    float b = 0.3;
    float m = 0.5;
    
    float s1 = size + ((sin(iTime* 0.01) * 0.5) + 0.5);
    float g1 = sdGyroid(p, s1, 0.03, 1.5);
    
    for (int i = 0; i < GYROID_DETAILS; i++) {
        if (i <= 1) g1 -= sdGyroid(p, s, t, b) * m;
        else g1 += sdGyroid(p, s, t, b) * m;
        s *= 1.75;
        m *= 0.75;
    }
    
    float d = g1 * 0.7;
   	
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

vec3 bg(vec3 rd) {
	vec3 col = vec3(0.0);
    float t = iTime * 0.2;
    
    float y = clamp(smoothstep(0.3, 1.0, rd.y * 0.5 + 0.5), 0.1, 1.0);
    col += y * waterColor * 6.0;
    
    float a = atan(rd.x, rd.z);
    float flares = 0.7 * sin(a*20.+t)*sin(a*2.-t)*sin(a*6.);
    flares *= smoothstep(.0, 1.0, y);
    col += flares;
    col = max(col, 0.);    
    return col;
}

// Camera matrix and movement from https://www.shadertoy.com/view/ldl3Dl
void camera(float cd, vec2 uv, float an, out vec3 ro, out vec3 rd) {
    ro = vec3( cd*cos(an), cd * sin(an), cd*sin(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    rd = normalize( uv.x*uu + uv.y*vv + 2.0*ww );
}

void main() {
    
    vec2 uv = (gl_FragCoord.xy-.5*iResolution.xy)/iResolution.y;
    
    if (wideangle) {
    	uv += sin(uv*2.0); // wideangle distortion
    }
            
    vec3 col = vec3(1.0);
    
    float t = iTime * 0.01;
    
    uv += sin(uv*20.+t)*.01;
    
    float an = -iTime * 0.05;
    
    vec3 ro, rd;
    float cd = 0.01; // camera distance
    camera(cd, uv, an, ro, rd); // get the camera
    
    float d = RayMarch(ro, rd);
    
    if(d<MAX_DIST) {
    	vec3 p = ro + rd * d;
    	vec3 n = GetNormal(p);
        
        p = transform(p);
        
    	float dif = dot(n, normalize(vec3(0.0,1.0,0.0)))*.5+.5;
        col *= dif;
    	col += dif;
        
        float b = sdGyroid(p, 10.798, 0.03, 0.3);
        col *= smoothstep(-0.05, 0.1, b);
        
        float cw = -0.02 + smoothstep(0.0, -0.5, n.y) * 0.02;
        float c = smoothstep(cw, -0.03, b);
        float cc = 1.0 - (sdGyroid(p+t, 6.789, 0.03, 0.3) * 4.0);
        float cc2 = 1.0 - (sdGyroid(p-t*0.5, 3.789, 0.03, 0.3) * 2.0);
        col += c * rocksColor * cc * cc2 * 3.0;
    }
    
    col = mix(col, bg(rd), smoothstep(0.0, MAX_DIST, d));
    
    gl_FragColor = vec4(col,1.0);
}