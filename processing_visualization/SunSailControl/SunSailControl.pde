private PointI cPoint;
private Sail sail;
private Light light;
private PhotoDiode pd1;
private PhotoDiode pd2;
private PhotoDiode pd3;
private PhotoDiode pd4;
private PhotoDiode[] pds;
private int historySize = 3;
private int updateTime = 1;
private int[] maxEngeries = new int[historySize];
private int[] minEnergies = new int[historySize];
private int iterator = 0;

// speed the sail shall move at ... this will have to be tested for the real thing
private float sailSpeed = 0.02;
// radius of the sail movement - will be determined on window size
private int radius;
// offset from the border - should at least be 10 ...
private int offset = 20;
// position on the cirvle for the sail to start
private float angle = 0;
// set some maximum energy for the calculation of the sail position ... TODO: this should not be needed in the final version!!! 
private float maxEnergy = pow(PI,3);
// a threshold for the sail to stop moving after reaching a position near the desired angle. 
private float sailThreshold = 0.1;
// virtual sail position that is determined by looking at its time being moved
private float sailVirtualAngle;




/**
 * setup method
 */
void setup() {
  size(400, 400, P2D);
  background(255);
  noStroke();
  
  // center point of the simulation
  cPoint = new PointI(width/2, height/2);
  
  // set some offset, so that things don't fly out of the window
  if (width <= height) {
    offset = (int)width*offset/100;
    radius = width/2 - offset;
  } 
  else {
    offset = (int)height*offset/100;
    radius = height/2 - offset;
  }
  
  // initialize photodiodes, light, and the sail.
  sail = new Sail(findPointOnCircle(cPoint.getX(), cPoint.getY(), radius, angle), angle);
  light = new Light(findPointOnCircle(cPoint.getX(), cPoint.getY(), radius + offset/2, angle), 1000);
  pds = new PhotoDiode[4];
//  println("lenght pds " + pds.length);
  for (int i=0; i<pds.length; i++) {
    pds[i] = new PhotoDiode(findPointOnCircle(cPoint.getX(), cPoint.getY(), radius + offset/4, 0.5*i*PI));
    pds[i].setAngle(0.5*i*PI); // addition for the angle ... may be used or not ...
  }

}




/**
 * draw method
 */
void draw() {
  clear();
  background(255);
  String sEnergys = "";
  float mark;
  
  // move the Light depending on mousemovement ...
  moveLight();
  // calculate the energy to be recognised by each photo diode
  for (int i=0; i<pds.length; i++) {
    pds[i].setEnergy(calculateLight(pds[i]));
  }
  
  // decide position of the sail to move to
//  angle = calculateSailDestination(pds);    // this is the old version
  PointF focalPoint = calculateFocalPoint();
  angle = calculateFocalPointAngle(focalPoint);    // this is the new version
  mark = angle;
  // decide which way the sail is to move depending on the sails position.
  angle = calcSailDirection(sail.getAngle(), angle);
  // set the tell the sail to move by a certain speed
  angle = sail.moveByAngle(sailSpeed * angle);
  
  // set the x- and y-position for the sail in order to set its display at the correct spot
  sail.setPosition(findPointOnCircle(cPoint.getX(), cPoint.getY(), radius, angle));
  
  // display stuff ...
  displayTrack(radius);
  for (int i=0; i<pds.length; i++) {
    pds[i].display();
  }
  sail.display();
  light.display();
  displayMark(mark);
  displayFocalPoint(focalPoint);
  
  // set iterator - used for some delayed operations
//  iterator++;    // the function making use of this doesnt work as intended right now ... dont use!  
  // introduce some randomness to the simulation ...
// insertSomeRandomness();    // not usefull as long as the iterator is not used ... this function causes problems 
}




/**
 * function for displaying the track
 * SIMULATION ONLY!
 */
void displayTrack(int r) {
  fill(230,240,255);
  ellipseMode(CENTER);
  ellipse(cPoint.getX(), cPoint.getY(), 2*r, 2*r);
} 


/**
 * draws a mark at the spot the sail shall move to ...
 * SIMULATION ONLY!
 */
void displayMark(float angle) {
  PointF mark = findPointOnCircle(cPoint.getX(), cPoint.getY(), radius, angle);
  fill(0);
  ellipse(mark.getX(), mark.getY(), 5, 5);
}


/**
 * display the focal point for debugging
 * SIMULATION ONLY!!!
 */
void displayFocalPoint(PointF focalPoint) {
//  float realX = (radius * focalPoint.getX()) + (width / 2);
//  float realY = -(radius * focalPoint.getY()) + (height / 2);
  float realX = (focalPoint.getX()) + (width / 2);
  float realY = -(focalPoint.getY()) + (height / 2);
  fill(255,255,0);
  stroke(100);
  line(width/2, height/2, realX, realY);
  noStroke();
  ellipse(realX, realY, 10, 10);
}



/**
 * function for finding the coordinates of a point on a circle
 * SIMULATION ONLY!
 */
PointF findPointOnCircle(int midX, int midY, int r, float a) {
  float x = midX + r*cos(a);
  float y = midY + r*sin(a);  
  return new PointF(x, y);
}


/**
 * moves the light n-times around the display
 * SIMULATION ONLY!
 */
void moveLight() {
  float angle;
  angle = map(mouseX, 0, width, 0, 4*PI); // map the length of window as 2 rounds of the sun
  light.setPos(findPointOnCircle(cPoint.getX(), cPoint.getY(), radius, angle));
  light.setAngle(angle); // just an additional information ..
}


/**
 * Calculates the appropriate energy that is measured by a given photodiode.
 * SIMULATION ONLY!
 */
float calculateLight(PhotoDiode pd) {
  float energy;
  float distance;
    
  distance = abs(pd.getAngle() - light.getAngle());
  // if the distance is greater than a half turn, things have to be corrected
  if (distance > PI) {
    distance = 2*PI - distance;
  }
  energy = ((PI - distance) / PI) * light.getEnergy();
  return energy;
}


/**
 * Determine the approximate position of the sail
 * SIMULATION ONLY - OPTIONAL!
 */
void insertSomeRandomness() {
  switch(iterator) {
    case 10: light.setEnergy(random(1,1)); println("set energy"); break;
    case 20: iterator = 0; println("reset"); break;
  }
}





/*
 * Here come the functions that will be used on the arduino board ....
 * They are pretty simple and don't contain any special classes.
 */
 
/**
 * calculate desired sail location ... the use of trigonometric
 * functions might cause problems with the arduino. 
 */ 
PointF calculateFocalPoint() {
  
  float x, y;
  int totalEnergy;
  
  // CHANGE THIS!!!! --> AVERAGE OF SEVERAL ENERGYS
  totalEnergy = 0;
  for (int i=0; i<pds.length; i++) {
    totalEnergy += pds[i].getEnergy();
  }
  
  x = ((1 * pds[0].getEnergy()) + (-1 * pds[2].getEnergy()));///totalEnergy;
  y = ((-1 * pds[1].getEnergy()) + (1 * pds[3].getEnergy()));///totalEnergy;
  
  
//  print("focalpoint is at   ");
//  print(x);
//  print(" : ");
//  println(y);
  
  return new PointF(x,y);
//  return calculateFocalPoint_2();
}


PointF calculateFocalPoint_2() {
  
  int totalEnergy = 0;
  for (int i=0; i<pds.length; i++) {
    totalEnergy += pds[i].getEnergy();
  }
  
  float[] xs = {pds[0].getEnergy() / totalEnergy, 0, -pds[2].getEnergy() / totalEnergy,0};
  float[] ys = {0, -pds[1].getEnergy() / totalEnergy, 0, pds[3].getEnergy() / totalEnergy};
  
  float area = 0;
  int n = 4;
  for (int i=0; i<(n-1); i++) {
    area += (xs[i] * ys[i+1]) - (xs[i+1] * ys[i]);
  }
//  area += (xs[n] * ys[0]) - (xs[0] * ys[n]);
  area = area * 0.5;
  
  
  float x = 0;
  float y = 0;
  
  for (int i=0; i<(n-1); i++) {
    x += (xs[i] + xs[i+1]) * ((xs[i] * ys[i+1]) - (xs[i+1] * ys[i]));
  }
//  x += (xs[n] + xs[0]) * ((xs[n] * ys[0]) - (xs[0] * ys[n]));
  x = x / (6 * area);
  
  for (int i=0; i<(n-1); i++) {
    y += (ys[i] + ys[i+1]) * ((xs[i] * ys[i+1]) - (xs[i+1] * ys[i]));
  }
//  y += (ys[n] + ys[0]) * ((xs[n] * ys[0]) - (xs[0] * ys[n]));
  y = y / (6 * area);
  
  return new PointF(x,y);
}


float calculateFocalPointDistance(PointF focalPoint) {
  float x = focalPoint.getX();
  float y = focalPoint.getY();
  return pow((x*x + y*y), 0.5);
}


float calculateFocalPointAngle(PointF focalPoint) {
  float x = focalPoint.getX();
  float y = focalPoint.getY();
  float angle;
  float vLength = calculateFocalPointDistance(focalPoint);
  
  angle = acos(x / (vLength));
  
  if (y > 0) {
    angle = 2*PI - angle;
  }
  
//  println(x);
  return angle;
}


/**
 * Calculate the direction the sail shall move in order to reach its destination.
 * 4REAL! 
 */
float calcSailDirection(float from, float to) {
  float diff;
  float diff2;
  float val;
  
  diff = from-to;
  
  // determine which angle would be the samller one in order the sail to move that way
  if (diff >= PI) {
    val = 1;
  }
  else if ((diff < PI) && (diff >= 0)) {
    val = -1;
  }
  else if ((diff < 0) && (diff >= -PI)) {
    val = 1;
  }
  else {
    val = -1;
  }
  
  // set a threshold for moving the sail, so that it may stop moving if the angle is below the threshold
  if (abs(diff) <= sailThreshold) {
    val = 0;
  }
  
//  println(from + "    " + to + "    " + val);
  return val;
}




















/*
 * functions that are not used right now ... and probably shouldn't be used ...
 */


/**
 * determine the approximate position of the sail.
 * TODO: THIS METHOD IS JUST A PLACEHOLDER - FILL WITH PROPER CONTENT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 * OPTIONAL!
 */ 
float determineSailPosition(int someINt) {
  if ((sail.getAngle() < 0.1) && (sail.getAngle() > (PI -.1))) {
    sailVirtualAngle = 0;
  }
  sailVirtualAngle += sailSpeed;  
  return 1.0;  // Yes - this is bullshit. Please replace it
}

/**
 * OLD VERSION ... the new one (calculateEnergyFocusAngle()
 * is much better!!!!!! ... but I'm not sure if it works well
 * on the arduino.
 *
 * Calculate the position the sail shall move to.
 * 4REAL!
 */
float calculateSailDestination(PhotoDiode[] lPDs) {
  int factor1;
  int factor2;
  float max1 = 0;
  int max_index_1 = 0;
  float max2 = 0;
  int max_index_2 = 0;
  float offset;
  float angle;
  float probability;
  float total = 0;
  PointF mark;

  // calculate the first and second maximum energy value - the sun/ light will
  // be between those two sensors
  for (int i=0; i<lPDs.length; i++) {
    if (lPDs[i].getEnergy() > max1) {
      max1 = lPDs[i].getEnergy();
      max_index_1 = i;
    }
  }
  for (int i=0; i<lPDs.length; i++) {
    if (lPDs[i].getEnergy() > max2 && i != max_index_1) {
      max2 = lPDs[i].getEnergy();
      max_index_2 = i;
    }
  }
  
  // calculate the minimum value as an offset for the energys      -      WHY         ?????
  offset = max2;
  for (int i=0; i<lPDs.length; i++) {
    if (lPDs[i].getEnergy() < offset) {
      offset = lPDs[i].getEnergy();
    }
  }
  for (int i=0; i<lPDs.length; i++) {
    total += lPDs[i].getEnergy();
  }
//  println("max1 = " + lPDs[i1].getEnergy() + " (" + i1 +   ") max2 = " + lPDs[i2].getEnergy() + " (" + i2 + ")"); 
  
  // what am I doing here ??? Comments ftw!
  if (max_index_1 == 0 && max_index_2 == 3) {
    factor1 = max_index_2;
    factor2 = max_index_1;
  }
  else if (max_index_1 == 3 && max_index_2 == 0) {
    factor1 = max_index_1;
    factor2 = max_index_2;
  }
  else if (max_index_1 < max_index_2) {
    factor1 = max_index_1;
    factor2 = max_index_2;
  }
  else {
    factor1 = max_index_2;
    factor2 = max_index_1;
  }
  
  // interpolate between the two points
//  total = max1 + max2;
//  total = 1000;
  println("offset: " + offset);
  probability = (lPDs[factor2].getEnergy()) / total;
  println("probability: " + probability);
  angle = 0.5*PI*factor1 + probability*0.5*PI;
//  angle = (0.5 * PI * lPDs[factor2].getEnergy()/pow(1000,1)) + (0.5 * PI * factor1);
//  angle = (0.5 * PI * lPDs[factor2].getEnergy()/maxEnergy) + (0.5 * PI * factor1);
//  angle = (0.5 * PI * (max1 + max2)*maxEnergy) + (0.5 * PI * factor1);

  return angle;
}
