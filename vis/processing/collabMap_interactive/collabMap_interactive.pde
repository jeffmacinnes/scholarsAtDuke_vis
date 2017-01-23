import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

// constant vars
float latN = 36.0146;
float latS = 35.9890;
float lonE = -78.9008;
float lonW = -78.9513;

int w = 1000;
int h = 627;
// create mercator projection object
MercatorMap mercatorMap = new MercatorMap(w, h, latN, latS, lonW, lonE);

PImage mapBG, mapOverlay;
Table collabTable;
Collaboration[] collabs;
Table buildingTable;
Building[] buildings;
PFont buildingFont;

color dotColor = #71B8B8;
color[] collabPalette = {#DBC954, #DF611D, #CE3136};

boolean is3D = false;
PeasyCam camera;


void settings() {
  if (is3D) {
    size(w, h, P3D);
  } else {
    size(w, h, P2D);
  }
}

void setup() {
  // load background image
  mapBG = loadImage("mapBG_light_small.png");
  mapOverlay = loadImage("mapBG_buildings_clean_black_small.png");

  // load display font
  buildingFont = createFont("Monaco", 16);

  // load tables
  collabTable = loadTable("vis_collaborations.tsv", "header, tsv");
  int n_collabs = collabTable.getRowCount();
  buildingTable = loadTable("buildingNames.tsv", "header, tsv");
  int n_buildings = buildingTable.getRowCount();

  // create arrays for collab objects and building objects
  collabs = new Collaboration[n_collabs];
  buildings = new Building[n_buildings];


  // read through collabs table, extract location info, build collaborations array
  for (int r = 0; r<n_collabs; r++) {
    TableRow row = collabTable.getRow(r);
    float srcLon = float(row.getString("a1_LON"));
    float dstLon = float(row.getString("a2_LON"));
    float srcLat = float(row.getString("a1_LAT"));
    float dstLat = float(row.getString("a2_LAT"));
    int totalCollabs = int(row.getString("totalCollabs"));

    // add to collabs array
    PVector srcPt = new PVector(srcLat, srcLon);
    PVector dstPt = new PVector(dstLat, dstLon);

    collabs[r] = new Collaboration(srcPt, dstPt, totalCollabs);
  }

  // read through buildings table, create buildings array
  for (int b = 0; b<n_buildings; b++) {
    TableRow row = buildingTable.getRow(b);

    float blLon = float(row.getString("LON"));
    float blLat = float(row.getString("LAT"));
    String blName = row.getString("NAME");

    PVector blPt = new PVector(blLat, blLon);

    //println(blLon);
    //println(blLat);
    //println(blName);

    buildings[b] = new Building(blPt, blName);
  }

  // animation settings
  if (is3D) {
    camera = new PeasyCam(this, 0, 0, 0, 50);
  }
  //noLoop();
  smooth();
}


void draw() {
  background(255);
  //println(frameRate);

  // show map 
  tint(255, 190);
  image(mapBG, 0, 0, width, height);
  tint(255,255);
  image(mapOverlay, 0, 0, width, height);

  //// show all collaborations
  for (Collaboration collab : collabs) {
    collab.update();
    collab.display();
  }

  //show some collaborations
  //for (int c = 0; c<1000; c++) {
  //    collabs[c].display();
  //    collabs[c].update();
  //}

  // show all buildings dots
  for (Building building : buildings) {
    building.update();
    building.displayDot();
  }
  
  // show any building names
  for (Building building : buildings) {
    building.displayName();
  }
}

void keyPressed() {
  if (key == 's') {
    save("collabMap.png");
  }
}

//************ CLASSES
class Building {
  // class vars
  PVector blPt_screen;
  String blName;
  boolean showBuilding;
  float textBoxHeight;
  float textBoxWidth;
  boolean multiLine;

  // constructor
  Building(PVector blPt_geo, String blName_tmp) {

    // read building name, format text box
    blName = blName_tmp;

    // convert point from geo to screen coordinates
    blPt_screen = mercatorMap.getScreenLocation(blPt_geo);
  }

  // update method
  void update() {
    // calculate distance between mouse and building location
    int minMouseDist = 7;
    float mouseDist = dist(blPt_screen.x, blPt_screen.y, mouseX, mouseY); 
    if (mouseDist <= minMouseDist) {
      showBuilding = true;
    } else {
      showBuilding = false;
    }
  }

  void displayDot() {
    noStroke();
    if (showBuilding) {
      fill(255, 0, 0);
      ellipse(blPt_screen.x, blPt_screen.y, 7, 7);
    } else {  
      // format/draw dot
      fill(dotColor);
      ellipse(blPt_screen.x, blPt_screen.y, 7, 7);
    }
  }

  void displayName() {
    if (showBuilding) {

      // format text background rect
      textSize(16);
      textBoxWidth = textWidth(blName); 
      textBoxHeight = 25;
      float xOffSet = 20;
      fill(255, 200);
      
      // if mouse on left half....
      if (mouseX < width/2) {
        textAlign(LEFT, BOTTOM);
        rect(mouseX+xOffSet-5, mouseY-textBoxHeight, textBoxWidth+10, textBoxHeight);
        
        // show text
        fill(50, 50, 50);
        textFont(buildingFont);
        text(blName, mouseX+xOffSet, mouseY); //, textBoxWidth+20, textBoxHeight);
      
      // if mouse on right half....
      } else {
        textAlign(RIGHT, BOTTOM);
        rect(mouseX-textBoxWidth-xOffSet-5, mouseY-textBoxHeight, textBoxWidth+10, textBoxHeight);
        
        // show text
        fill(50, 50, 50);
        textFont(buildingFont);
        text(blName, mouseX-xOffSet, mouseY); //, textBoxWidth+20, textBoxHeight);
      }
    }
  }
}


class Collaboration {
  // class vars
  PVector leftPt_screen, rightPt_screen;
  PVector connVec, orthVec, leftPt_orthVec, rightPt_orthVec;
  PVector leftPt_ctrl, rightPt_ctrl;
  color connColor;
  float collabDist;
  float ctrlVecLen, orthVecRotDeg;
  boolean showConnection;


  // constructor
  Collaboration(PVector srcPt_geo, PVector dstPt_geo, int totalCollabs) {

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
    if (totalCollabs == 1) {
      connColor = color(collabPalette[0], 120);
    } else if ((totalCollabs >= 1) && (totalCollabs<5)) {
      connColor = color(collabPalette[1], 120);
    } else {
      connColor = color(collabPalette[2], 120);
    }


    // calculate distance between points
    collabDist = leftPt_screen.dist(rightPt_screen);

    //vector describing the straight line between points
    connVec = PVector.sub(leftPt_screen, rightPt_screen);    
    connVec.normalize();

    // vector othogonal to the straight line connection
    orthVec = connVec.copy();
    orthVec.rotate(HALF_PI);

    // define length of each ctrl pt vector (this will set the arc-iness of each connection)
    float maxOffset = 1.1;
    ctrlVecLen = collabDist * .2 * map(random(0, 1), 0, 1, 1, maxOffset);

    if (is3D) {
      // create ctrlPtVectors
      leftPt_ctrl = leftPt_screen.copy();
      leftPt_ctrl.z = ctrlVecLen;

      rightPt_ctrl = rightPt_screen.copy();
      rightPt_ctrl.z = ctrlVecLen;
    } else {
      // create ctrlPtVectors
      orthVecRotDeg = random(0, 50);    // more extreme than in static version, to show separation
      leftPt_orthVec = orthVec.copy();
      leftPt_orthVec.rotate(radians(orthVecRotDeg));
      leftPt_orthVec.mult(ctrlVecLen);
      rightPt_orthVec = orthVec.copy();
      rightPt_orthVec.rotate(radians(360-orthVecRotDeg));
      rightPt_orthVec.mult(ctrlVecLen);

      // define control points for each
      leftPt_ctrl = PVector.add(leftPt_screen, leftPt_orthVec);
      rightPt_ctrl = PVector.add(rightPt_screen, rightPt_orthVec);
    }
  }

  // update method
  void update() {
    // calculate distance between mouse and collaboration locations
    int minMouseDist = 7;
    float mouse2leftPt_dist = dist(leftPt_screen.x, leftPt_screen.y, mouseX, mouseY);
    float mouse2rightPt_dist = dist(rightPt_screen.x, rightPt_screen.y, mouseX, mouseY);
    if ((mouse2leftPt_dist <= minMouseDist) || (mouse2rightPt_dist <= minMouseDist)) {
      showConnection = true;
    } else {
      showConnection = false;
    }
  }

  // display method
  void display() {

    if (showConnection == true) {
      // draw the connection
      noFill();
      stroke(connColor);
      if (is3D) {
        bezier(leftPt_screen.x, leftPt_screen.y, leftPt_screen.z, 
          leftPt_ctrl.x, leftPt_ctrl.y, leftPt_ctrl.z, 
          rightPt_ctrl.x, rightPt_ctrl.y, rightPt_ctrl.z, 
          rightPt_screen.x, rightPt_screen.y, rightPt_screen.z);
      } else {
        bezier(leftPt_screen.x, leftPt_screen.y, 
          leftPt_ctrl.x, leftPt_ctrl.y, 
          rightPt_ctrl.x, rightPt_ctrl.y, 
          rightPt_screen.x, rightPt_screen.y);
      }
    }

    // show reference lines
    noFill();
    stroke(connColor);
    //line(leftPt_screen.x, leftPt_screen.y, rightPt_screen.x, rightPt_screen.y);
    //stroke(0, 50);
    //line(leftPt_screen.x, leftPt_screen.y, leftPt_ctrl.x, leftPt_ctrl.y);
    //line(rightPt_screen.x, rightPt_screen.y, rightPt_ctrl.x, rightPt_ctrl.y);

    //// show dots
    //noStroke();
    //if (showConnection){
    //  tint(255, 120);
    //} else {
    //  tint(255, 255);
    //}
    //fill(dotColor);
    //ellipse(leftPt_screen.x, leftPt_screen.y, 7, 7);
    //ellipse(rightPt_screen.x, rightPt_screen.y, 7, 7);
  }
}