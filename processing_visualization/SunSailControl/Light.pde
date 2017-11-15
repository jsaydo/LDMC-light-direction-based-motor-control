class Light {
  float energy;
  PointF pos;
  float angle = 0;
  
  Light(PointF pos, float energy) {
    this.pos = pos;
    this.energy = energy;
  }
  
  
  float getAngle() {
    return this.angle;
  }
  
  void setAngle(float angle) {
    this.angle = angle;
    if (this.angle >= (2*PI)) {
      this.angle += (-2*PI);
    }
  }
  
  float getEnergy() {
    return this.energy;
  }
  
  void setEnergy(float energy) {
    this.energy = energy;
  }
  
  PointF getPos() {
    return this.pos;
  }
  
  void setPos(PointF pos) {
    this.pos = pos;
  }
  
  void display() {
    fill(240,0,0);
    ellipseMode(CENTER);
    ellipse(pos.getX(), pos.getY(), 20, 20);
  }
  
  
}
