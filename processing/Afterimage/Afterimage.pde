import processing.video.*;

Capture video;
PImage current, previous, result;
int W = 160, H = 120;
float THRESHOLD = 50;
float FADE_SECONDS = 3;
float[] trails = new float[W * H];
boolean hasPrevious = false;
int warmup = 15;
int lastTime;

void setup() {
  size(800, 600);
  frameRate(30);
  surface.setTitle("Afterimage");
  current = createImage(W, H, RGB);
  previous = createImage(W, H, RGB);
  result = createImage(W, H, RGB);
  String[] cameras = Capture.list();
  printArray(cameras);
  if (cameras.length == 0) {
    println("No camera found. Connect a camera and run again.");
    exit();
    return;
  }
  video = new Capture(this, cameras[0]);
  video.start();
  lastTime = millis();
}

void draw() {
  int now = millis();
  float fade = (now - lastTime) / 1000.0 / FADE_SECONDS;
  lastTime = now;
  boolean fresh = video != null && video.available();
  if (fresh) {
    video.read();
    int sw = min(video.width, video.height * W / H);
    int sh = sw * H / W;
    current.copy(video, (video.width - sw) / 2, (video.height - sh) / 2, sw, sh, 0, 0, W, H);
    if (!hasPrevious || warmup > 0) {
      previous.copy(current, 0, 0, W, H, 0, 0, W, H);
      warmup = max(0, warmup - 1);
    }
    current.loadPixels();
    previous.loadPixels();
  }
  result.loadPixels();
  for (int i = 0; i < trails.length; i++) {
    trails[i] = max(0, trails[i] - fade);
    if (fresh && hasPrevious) {
      color a = current.pixels[i];
      color b = previous.pixels[i];
      float difference = distSq(red(a), green(a), blue(a), red(b), green(b), blue(b));
      if (difference > THRESHOLD * THRESHOLD) trails[i] = 1;
    }
    result.pixels[i] = color(lerp(244, 46, trails[i]), lerp(240, 100, trails[i]), lerp(230, 91, trails[i]));
  }
  if (fresh) {
    previous.copy(current, 0, 0, W, H, 0, 0, W, H);
    hasPrevious = true;
  }
  result.updatePixels();
  pushMatrix();
  translate(width, 0);
  scale(-1, 1);
  image(result, 0, 0, width, height);
  popMatrix();
}

float distSq(float r1, float g1, float b1, float r2, float g2, float b2) {
  return (r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2);
}
