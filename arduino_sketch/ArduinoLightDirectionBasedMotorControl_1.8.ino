/**
  Copyright 2014 Saydo, Jean
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
      http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 **/

int licenseFrequency = 42000;
int increment = 0;
String LICENSE = "\n\n\n  Copyright 2014 Saydo, Jean\n"
"  Licensed under the Apache License, Version 2.0 (the \"License\");\n"
"  you may not use this file except in compliance with the License.\n"
"  You may obtain a copy of the License at\n"
"  \n"
"      http://www.apache.org/licenses/LICENSE-2.0\n"
"  \n"
"  Unless required by applicable law or agreed to in writing, software\n"
"  distributed under the License is distributed on an \"AS IS\" BASIS,\n"
"  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n"
"  See the License for the specific language governing permissions and\n"
"  limitations under the License.\n\n\n";




/**
 * Notice: when compiling and sending code to the Arduino, the motor will be
 * turning during startup when it is plugged in ... this is not desired, so 
 * that the motor has to be unplugged during startup.
 * This is important in order to get the correct starting point for the motor.
 * Otherwise it will have an offset in its position.
 */ 

 
// a threshold for the sail to halt, when it is near the desired angle (mesured in RAD)
float sailThreshold = 0.2;
// angle the sail shall move to (mesured in RAD)
float desiredAngle = 0;
// angle the sail currently is located (mesured in RAD)
float currentAngle = 0;
// direction for the motor to move the sail (-1, 0, 1)
int motorDirection = 0;
// flag that indicates whether the sun direction vector is valid or not (eg. too short)
boolean isVectorValid = false;
// Threshold for the length of the sun direction vector to be considered as useful
float vLengthThreshold = 4;
// time the motor needs to turn the sail one time around (in ms) - NEEDS TO BE TESTED!!!!
int totalTurnTime = 20500;
// time relative position of the motor (in ms)
int timeRelativeMotorPosition = 0;
// time the motor should be active on each loop (in ms)
int motorActiveTime = 1000;
// delay for restarting the loop (in ms)
int loopDelayTime = 5000;


// maximum temperature before the sail is set to shade mode
float temperature_threshold = 28.0;
// max temperature converted into the the signal value
float temperature_threshold_signal;


// the time in ms it takes to turn for a unit of 2*PI/100
float stepSize = totalTurnTime / (20*PI);


// pins for the motor control
int motorPowerPin = 4;
int motorDirectionPin = 5;


// pin for temperature
int temperaturePin = A5;

// timer amount of seconds spent on the
unsigned long timer = 0;

// counter for debugging
unsigned long counter = 0;







//===============================================================================

void setup() {
  
  Serial.println(LICENSE);
  // initialize serial communications at 9600 bps:
  Serial.begin(9600);
  
  // set up pins ...
  pinMode(motorDirectionPin, OUTPUT);
  pinMode(motorPowerPin, OUTPUT);
  
  // and set motor to halt
  digitalWrite(motorPowerPin, HIGH);
  
  temperature_threshold_signal = 
        0.7889311874 * temperature_threshold + 518.0745826547;
  
}





//--------------------------------------------------------------------------------

void loop() {
  
  Serial.println("");
  Serial.println("");
  
  counter += 1;
  Serial.print("round: ");
  Serial.println(counter);
  Serial.print("seconds: ");
  Serial.println(timer);
	
  float travelTime = 0;
  float deltaAngle = 0;
  int motorDirection = 0;
  boolean isTooHot = false;
  
  // declare and read light signal sensors
  int one = analogRead(A0);
  int two = analogRead(A1);
  int three = analogRead(A2);
  int four = analogRead(A3);
  
  // display license every now and then
  displayLicense();
  
  // just display the light sensors signals (for debugging)
  displayLightSignals(one, two, three, four);
  

  // check temperature and decide whether the temperature is to hot or not
  isTooHot = checkTemperature(temperaturePin, temperature_threshold_signal);
  
  // calculate the desired angle. Will return -1 if the vLengthThreshold is 
  // not matched, meaning that the signal is too weak or all signals are too
  // similar.
  desiredAngle = calculateDesiredAngle(isTooHot, vLengthThreshold, one, two, three, four);
  
  // calculate the shortest way for the sail to the destination
  deltaAngle = calculateDeltaAngle(currentAngle, desiredAngle, sailThreshold);

  // calculate the time the sail will need to turn to the desired position.
  travelTime = abs(deltaAngle) * 10 * stepSize;
  
  // calculate the motor direction
  if (deltaAngle > 0.0) {  
    motorDirection = 1;
  }
  else if (deltaAngle < 0.0) {
    motorDirection = -1;
  }
  else {
    motorDirection = 0;
  }

  // finally turn the sail/ motor ... and record the time it spent doing so
  timer += moveMotor(motorDirection, travelTime);

  // display the calculated angles
  displayAngles(currentAngle, desiredAngle);
  
  // give the arduino some rest ...
  delay(loopDelayTime);
  timer += (loopDelayTime / 1000);
}









//========================================================================================




/**
 * Checks the current temperature signal and returns a boolean value for whether
 * the temperature is within the threshold or not.
 */
boolean checkTemperature(int pin, float temperature_threshold_signal) {
  
  int temperature_signal = analogRead(pin);
  
  float temperature = 1.2654580648 * temperature_signal - 655.5239029342;
  
  Serial.print("current Temperature: ");
  Serial.print(temperature_signal);
  Serial.print("   -->   ");
  Serial.print(temperature);
  Serial.println(" °C");
  
  if (temperature_signal <= temperature_threshold_signal) {
    Serial.println("Temperature is fine");
    return true;
  }
  else {
    Serial.println("Temperature is too high. The sail will go to shade mode.");
    return false;
  }
  
}




/**
 * Calculate desired Angle, depending on the sun's direction and the sail's mode.
 */
float calculateDesiredAngle(boolean temperatureThreshold, float minimalVectorLength, int one, int two, int three, int four) {
  
  float desiredAngle;
  
  desiredAngle = calculateFocalPointAngle(minimalVectorLength, one, two, three, four);
  
  // check if the sail should move to the opposite side
  if ((temperatureThreshold == true) && (desiredAngle >= 0)) { // 2nd check because otherwise wired stuff happenes
    
    if (desiredAngle < PI) {
      desiredAngle += PI;
    }
    else {
      desiredAngle += -PI;
    }
    
  }
  
  return desiredAngle;
}




/**
 * Calculates the desired sail location.
 */ 
float calculateFocalPointAngle(float minimalVectorLength, int one, int two, int three, int four) {
  
  float x, y;
  float vLength;
  float angle;
  float totalEnergy;
  
  
  // CHANGE THIS!??! --> AVERAGE OF SEVERAL ENERGYS?
//  totalEnergy = analogRead(A0) + analogRead(A1) + analogRead(A2) + analogRead(A3);
  
  // calculate the coordinates of the sun direction vector and invert it,
  // because the signals of the sensors are inverted (1023 = no light, 
  // 0 = max light) 
//  x = -1 * (((1 * analogRead(A0)) + (-1 * analogRead(A2)))/totalEnergy);
//  y = -1 * (((-1 * analogRead(A1)) + (1 * analogRead(A3)))/totalEnergy);
  x = -1 * ((1 * one) + (-1 * three));
  y = -1 * ((-1 * two) + (1 * four));
  
  
  // calculate the length of the signal vector
  vLength = pow((x*x + y*y), 0.5);
  
  Serial.print("VectorSize = ");
  Serial.println(vLength);  
  
  // only move the sail if the signal vector's length is above the threshold
  if (vLength < minimalVectorLength) {
    
    return -1.0;
    
  }
  else {
    
    // calculate angle
    angle = acos(x / (vLength));
    
    // if needed, correct it
    if (y > 0) {
      angle = 2*PI - angle;
    }
    
    return angle;
    
  }
  
}




/**
 * calculates the shortest way for the sail to travel to its destination.
 * Returns 0 if the desired angle is negative, above 2*PI or if the delta angle 
 * is below the given threshold. Thus only positive values are accepted.
 */
float calculateDeltaAngle(float currentAngle, float desiredAngle, float threshold) {
  
  float deltaAngle = 0;
  
  // check if the desired angle is between 0 and 2*PI (i.e one circle turn)
  if ((desiredAngle >= 0) && (desiredAngle < 2*PI)) {
    
    deltaAngle = desiredAngle - currentAngle;
    
    // check if there is a shorter way for the sail to reach its destination.
    if (deltaAngle > PI) {
      deltaAngle += -2*PI;
    }
    else if (deltaAngle < -PI) {
      deltaAngle += 2*PI;
    }
    
    Serial.print("deltaAngle = ");
    Serial.println(deltaAngle);
    
    // check if the delta angle is big enough (prevents too small movements)
    if (abs(deltaAngle) >= threshold) {
      
      return deltaAngle;
      
    }
    else {
      
      Serial.println("deltaAngle too small");
      return 0;
      
    }
    
  }
  else {
    
    return 0;
  
  }
  
}




/**
 * Move the motor
 * Returns the number of seconds spent on this task
 */
int moveMotor(int direction, float travelTime) {
  
  switch (direction) {
    case 0:
      Serial.println("Motor does nothing!");
      digitalWrite(motorPowerPin, HIGH);
      return 0;
    case 1:
      Serial.print("Motor goes left ... ");
      digitalWrite(motorPowerPin, HIGH);
      delay(1000);
      digitalWrite(motorDirectionPin, HIGH);
      delay(500);
      digitalWrite(motorPowerPin, LOW);
      delay(travelTime);
      digitalWrite(motorPowerPin, HIGH);
      delay(500);
      currentAngle = desiredAngle;
      Serial.println("done");    
      return 2 + (travelTime / 1000);
    case -1:
      Serial.print("Motor goes right ... ");
      digitalWrite(motorPowerPin, HIGH);
      delay(1000);
      digitalWrite(motorDirectionPin, LOW);
      delay(500);
      digitalWrite(motorPowerPin, LOW);
      delay(travelTime);
      digitalWrite(motorPowerPin, HIGH);
      delay(500);
      currentAngle = desiredAngle;
      Serial.println("done");
      return 2 + (travelTime / 1000);
  }
  	
}




/**
 * Calculate the direction the sail shall move in order to reach its destination.
 * THIS IS NOW OBSOLETE ... DELETE IT!!!
 */
int calcSailDirection(float from, float to) {
  
  float diff;
  float diff2;
  int val;
  
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
  
  return val;
}







//-----------------------------------------------------------------

/**
 * Simply display the signals of the light sensors (for debugging).
 */
void displayLightSignals(int one, int two, int three, int four) {
  
  Serial.print("A0 ");
  Serial.print(one);
  Serial.print("    A1 ");
  Serial.print(two);
  Serial.print("    A2 ");
  Serial.print(three);
  Serial.print("    A3 ");
  Serial.print(four);
  Serial.println("");

}


/**
 * Simply display angles (for debugging)
 */
void displayAngles(float from, float to) {
  
  Serial.print("currentAngle = ");
  Serial.print(currentAngle);
  Serial.print(" ---- desiredAngle = ");
  Serial.print(desiredAngle);
  Serial.println("");

}




//-----------------------------------------------------------


/**
 * Simply display the license.
 */
void displayLicense() {
  
  if (increment > licenseFrequency) { 
    Serial.println(LICENSE);
    increment = 0;
  }
  increment++;
  
}

