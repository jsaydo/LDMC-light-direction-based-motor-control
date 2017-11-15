class PointF {
  float xPos;
  float yPos;
  
  PointF(float x, float y) {
    this.xPos = x;
    this.yPos = y;
  }
      
  float getX() {
    return this.xPos;
  }
      
  void setX(float x) {
    this.xPos = x;
  }
      
  float getY() {
    return this.yPos;
  }
      
  void setY(float y) {
    this.yPos = y;
  }
  
  String getString() {
    return this.xPos + ":" + this.yPos;
  }
}

class PointI {
  int xPos;
  int yPos;
  
  PointI(int x, int y) {
    this.xPos = x;
    this.yPos = y;
  }
      
  int getX() {
    return this.xPos;
  }
      
  void setX(int x) {
    this.xPos = x;
  }
      
  int getY() {
    return this.yPos;
  }
      
  void setY(int y) {
    this.yPos = y;
  } 
}
