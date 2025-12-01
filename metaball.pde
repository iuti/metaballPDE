PShader metaShader;
int numBlobs = 12; 
Blob[] blobs = new Blob[numBlobs];
float[] blobCoords = new float[numBlobs * 2];

// 余白管理用の変数
float marginTop = 20;
float marginBottom = 40;
float marginLeft = 20;
float marginRight = 20;

// 時間操作用の変数
boolean isTimeStopping = false; 
float currentFriction = 0.993;   
float currentGravity = 0.2;     

// イージング用の進行度（0.0 = 通常 〜 1.0 = 完全停止）
float stopProgress = 0.0; 

// ヒートマップ表示モード
boolean showHeatmap = false;

void setup() {
  size(800, 800, P2D); 
  metaShader = loadShader("metaball.glsl");
  
  for (int i = 0; i < numBlobs; i++) {
    blobs[i] = new Blob(random(width), random(height/2));
  }
}

void draw() {
  
  if (isTimeStopping) {
    // 停止に向かってカウントアップ (上限 1.0)
    stopProgress += 0.02;
    if (stopProgress > 1.0) stopProgress = 1.0;
  } else {
    // 通常に向かってカウントダウン (下限 0.0)
    stopProgress -= 1;
    if (stopProgress < 0.0) stopProgress = 0.0;
  }
  
  // --- 2. イージング計算（ここがポイント） ---
  // 単純な直線的な変化ではなく、3乗することでカーブを作る
  // t が 0.1 のとき -> ease は 0.001 (ほとんど変化しない)
  // t が 0.9 のとき -> ease は 0.729 (急激に変化する)
  float t = stopProgress;
  float ease = t * t; // 「3乗」のカーブ（加速感が出る）

  // map関数を使って、ease (0.0〜1.0) を物理パラメータに変換
  // Friction: 0.99 (通常) -> 0.80 (停止)
  currentFriction = map(ease, 0.0, 1.0, 0.993, 0.80);
  // Gravity: 0.2 (通常) -> 0.0 (停止)
  currentGravity = map(ease, 0.0, 1.0, 0.2, 0.0);


  // --- 3. 物理演算 ---
  // スペースキー長押しの撹拌
  if (keyPressed && key == ' ') {
    for (Blob b : blobs) {
      PVector force = PVector.random2D();
      force.mult(15);
      b.vel.add(force);
    }
  }

  for (int i = 0; i < numBlobs; i++) {
    blobs[i].update();
    blobCoords[i*2] = blobs[i].pos.x;
    blobCoords[i*2+1] = blobs[i].pos.y;
  }

  // --- 4. シェーダー描画 ---
  metaShader.set("u_resolution", float(width), float(height));
  metaShader.set("blobs", blobCoords, 2);
  metaShader.set("numBlobs", numBlobs);
  metaShader.set("showHeatmap", showHeatmap ? 1 : 0);
  
  shader(metaShader);
  rect(0, 0, width, height);
  resetShader();
  
  // --- 5. 状態表示 ---
  fill(255);
  textSize(16);
  text("T Key: Toggle Time Stop", 20, 40);
  text("G Key: Toggle Heatmap [" + (showHeatmap ? "ON" : "OFF") + "]", 20, 110);
  
  // バーで進行度を表示
  noFill(); stroke(255);
  rect(20, 60, 100, 10);
  noStroke(); fill(255);
  rect(20, 60, 100 * stopProgress, 10); // 進行度バー
  
  text("Progress: " + nf(stopProgress, 1, 2), 130, 70);
  text("Ease Val: " + nf(ease, 1, 3), 130, 90);
}

void keyReleased() {
  if (key == 't' || key == 'T') {
    isTimeStopping = !isTimeStopping;
  }
  if (key == 'g' || key == 'G') {
    showHeatmap = !showHeatmap;
  }
}

class Blob {
  PVector pos, vel;
  Blob(float x, float y) {
    pos = new PVector(x, y);
    vel = new PVector(random(-2, 2), random(-2, 2));
  }
  void update() {
    vel.y += currentGravity; 
    vel.mult(currentFriction); 
    
    pos.add(vel);
    
    // 壁の跳ね返り（余白を考慮）
    if (pos.x < marginLeft) { pos.x = marginLeft; vel.x *= -0.95; }
    if (pos.x > width - marginRight) { pos.x = width - marginRight; vel.x *= -0.95; }
    if (pos.y < marginTop) { pos.y = marginTop; vel.y *= -0.95; }
    if (pos.y > height - marginBottom) { pos.y = height - marginBottom; vel.y *= -0.95; }
  }
}
