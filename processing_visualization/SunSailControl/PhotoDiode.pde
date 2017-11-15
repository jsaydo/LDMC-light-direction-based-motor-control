class PhotoDiode {
  PointF pos = new PointF(0,0);
  float angle = 0;
  float energy = 0;
  
  PhotoDiode() {
  }
  
  PhotoDiode(PointF pos) {
    this.pos = pos;
  }
  
  
  float getAngle() {
    return this.angle;
  }
  
  void setAngle(float angle) {
    this.angle = angle;
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
    int value = (int)(map(this.energy, 0, 1000, 0, 255));
    fill(0,value,0);
    ellipseMode(CENTER);
    ellipse(pos.getX(), pos.getY(), 20, 20);
  }
  
}
