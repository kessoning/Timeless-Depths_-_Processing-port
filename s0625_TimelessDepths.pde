/* 
 * Copyright 2020 - Giovanni Muzio | Kesson
 * https://kesson.io
 *
 * Port from Shadertoy
 * https://www.shadertoy.com/view/ttlyWB
 *
*/

PShader shader, blur;

void settings() {
  size(800, 800, P3D);
}

void setup() {
  // The shader  
  shader = loadShader("shader.glsl");
  shader.set("iResolution", float(width), float(height));
  shader.set("iTime", 0.0);
  shader.set("speed", 2.0);
  
  // Post Processing blur effect
  blur = loadShader("blur.glsl");
  blur.set("iResolution", float(width), float(height));
  
}

void draw() {
  shader.set("iTime", millis() / 1000.0);
  blur.set("iTime", millis() / 1000.0);
  
  shader(shader);
  rect(0, 0, width, height);
  filter(blur);
  
}
