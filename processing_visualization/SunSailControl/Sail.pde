class Sail {
  float angle = 0;
  PointF position;
  
  Sail(float posX, float posY, float angle) {
    this.angle = angle;
    this.position = new PointF(posX, posY);
  }
  
  Sail(PointF position, float angle) {
    this.angle = angle;
    this.position = position;
  }
  
  
  void display() {
    fill(0,0,240);
    rectMode(CENTER);
    rect(position.getX(), position.getY(), 20, 20);
  }
  
  
  void setPosition(PointF position) {
    this.position = position;
  }
  
  float getAngle() {
    return this.angle;
  }
  
  float moveByAngle(float angle) {
    this.angle += angle;
    
    if (this.angle < 0) {
      this.angle += (2*PI);
    }
    else if (this.angle >= 2*PI) {
      this.angle += (-2*PI);
    }
    return this.angle;
  }
  
  
  void moveSail() {
    
  }
  
  
}
