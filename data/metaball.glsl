#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 blobs[100];
uniform int numBlobs;

void main() {
    vec2 st = gl_FragCoord.xy;
    st.y = u_resolution.y - st.y; // 上下反転補正

    float sum = 0.0;
    
    // 1. 通常のボールの計算（プラスの重み）
    for (int i = 0; i < 100; i++) {
        if (i >= numBlobs) break;
        float d = distance(st, blobs[i]);
        if (d > 0.0) {
            sum += 6000.0 / d;
        }
    }

    // 2. 壁からの「逆の重み」の計算（マイナスの重み）
    // 壁を「巨大なマイナスのボール」とみなします
    
    float wallStrength = 000.0; // 壁の反発力の強さ（調整してください）

    // 現在のピクセルから、上下左右それぞれの壁までの距離を測る
    float distLeft   = st.x;
    float distRight  = u_resolution.x - st.x;
    float distTop    = st.y;
    float distBottom = u_resolution.y - st.y;

    // 一番近い壁までの距離を採用する
    float distToWall = min(min(distLeft, distRight), min(distTop, distBottom));

    // 壁に近いほど sum を「減らす」
    if (distToWall > 0.0) {
        sum -= wallStrength / distToWall;
    }

    // --- 以下、前回と同じ描画ロジック ---

    vec3 bgColor = vec3(0.05, 0.05, 0.1); 
    vec3 lineColor = vec3(0.2, 1.0, 0.9); 

    float threshold = 350.0; 
    float range = 12.0;      

    // sum が減算された結果を使っているので、壁際は値が小さくなり、描画されにくくなる
    float distFromPeak = abs(sum - threshold);
    float t = 1.0 - smoothstep(0.0, range, distFromPeak);
    
    vec3 finalColor = mix(bgColor, lineColor, t);

    gl_FragColor = vec4(finalColor, 1.0);
}