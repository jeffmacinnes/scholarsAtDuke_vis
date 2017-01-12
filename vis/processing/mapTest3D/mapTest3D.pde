import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

// import PDF library

// constant vars
float latN = 36.0109;
float latS = 35.9905;
float lonE = -78.9086;
float lonW = -78.9483;

int w = 7689/4;
int h = 4884/4;
// create mercator projection object
MercatorMap mercatorMap = new MercatorMap(w, h, latN, latS, lonW, lonE);

PImage mapBG, mapOverlay;
Table collabTable;
Collaboration[] collabs;


PeasyCam camera;

void settings() {
  size(w, h, P3D);
}

void setup() {
  // load background image
  mapBG = loadImage("dark1.png");
  mapOverlay = loadImage("buildingOverlay.png");

  // load table
  collabTable = loadTable("vis_collaborations.tsv", "header, tsv");
  int n_collabs = collabTable.getRowCount();

  // create array for collab objects
  collabs = new Collaboration[n_collabs];

  // read through table, extract location info, build collaborations array
  for (int r = 0; r<n_collabs; r++) {
    TableRow row = collabTable.getRow(r);
    float srcLon = float(row.getString("src_LON"));
    float dstLon = float(row.getString("dst_LON"));
    float srcLat = float(row.getString("src_LAT"));
    float dstLat = float(row.getString("dst_LAT"));

    // add to collabs array
    PVector srcPt = new PVector(srcLat, srcLon);
    PVector dstPt = new PVector(dstLat, dstLon);
    collabs[r] = new Collaboration(srcPt, dstPt);
  }

  // animation settings
  camera = new PeasyCam(this, 0, 0, 0, 50);
  //noLoop();
  smooth();  
}


void draw() {
 background(0); 

 // show map 
 image(mapBG, 0, 0, width, height);
 image(mapOverlay, 0, 0, width, height);

 //// show all collaborations
 for (Collaboration collab : collabs) {
 collab.display();
 }
  
 //show some collaborations
 //for (int c = 0; c<1000; c++) {
 //collabs[c].display();
 //}
 
 // show overlay of buildings
 //image(mapOverlay, 0, 0, width, height);
 
 // save
 //save("mapTest.png");
}



//************ CLASSES
class Collaboration {
  // class vars
  PVector leftPt_screen, rightPt_screen;
  PVector connVec, orthVec, leftPt_orthVec, rightPt_orthVec;
  PVector leftPt_ctrl, rightPt_ctrl;
  color connColor;
  float collabDist;
  float ctrlVecLen, orthVecRotDeg;


  // constructor
  Collaboration(PVector srcPt_geo, PVector dstPt_geo) {

    // convert the locations from geo (lat/lon) to screen (x,y)
    // figure out which point is further west (note: y-geo coord = lon = x screen coor) 
    if (srcPt_geo.y <= dstPt_geo.y) {
      leftPt_screen = mercatorMap.getScreenLocation(srcPt_geo);
      rightPt_screen = mercatorMap.getScreenLocation(dstPt_geo);
    } else {
      leftPt_screen = mercatorMap.getScreenLocation(dstPt_geo);
      rightPt_screen = mercatorMap.getScreenLocation(srcPt_geo);
    }

    // set color
    connColor = color(230, 142, 55, 120);

    // calculate distance between points
    collabDist = leftPt_screen.dist(rightPt_screen);

    //vector describing the straight line between points
    connVec = PVector.sub(leftPt_screen, rightPt_screen);    
    connVec.normalize();

    // vector othogonal to the straight line connection
    orthVec = connVec.copy();
    orthVec.rotate(HALF_PI);

    // define length of each ctrl pt vector
    float maxOffset = 1.1;
    ctrlVecLen = collabDist * .4 * map(random(0, 1), 0, 1, 1, maxOffset);

    // create ctrlPtVectors
    //orthVecRotDeg = 10.0;
    leftPt_ctrl = leftPt_screen.copy();
    leftPt_ctrl.z = ctrlVecLen;
    
    rightPt_ctrl = rightPt_screen.copy();
    rightPt_ctrl.z = ctrlVecLen;
    
  }

  // display method
  void display() {
    // draw the connection
    noFill();
    stroke(connColor);
    bezier(leftPt_screen.x, leftPt_screen.y, leftPt_screen.z, 
      leftPt_ctrl.x, leftPt_ctrl.y, leftPt_ctrl.z,
      rightPt_ctrl.x, rightPt_ctrl.y, rightPt_ctrl.z, 
      rightPt_screen.x, rightPt_screen.y, rightPt_screen.z);


    // show reference lines
    noFill();
    stroke(connColor);
    //line(leftPt_screen.x, leftPt_screen.y, rightPt_screen.x, rightPt_screen.y);
    //stroke(0, 50);
    //line(leftPt_screen.x, leftPt_screen.y, leftPt_ctrl.x, leftPt_ctrl.y);
    //line(rightPt_screen.x, rightPt_screen.y, rightPt_ctrl.x, rightPt_ctrl.y);

    // show dots
    noStroke();
    fill(255, 200);
    ellipse(leftPt_screen.x, leftPt_screen.y, 10, 10);
    //fill(255, 0, 0);
    ellipse(rightPt_screen.x, rightPt_screen.y, 10, 10);
  }
}