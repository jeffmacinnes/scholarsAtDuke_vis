import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;


// constant vars
float latN = 36.0146;
float latS = 35.9890;
float lonE = -78.9008;
float lonW = -78.9513;

int w = 9780;
int h = 6130;
// create mercator projection object
MercatorMap mercatorMap = new MercatorMap(w, h, latN, latS, lonW, lonE);

PImage mapBG, mapOverlay;
Table collabTable;
Collaboration[] collabs;

color dotColor = #71B8B8;
color[] collabPalette = {#DBC954, #DF611D, #CE3136};
//color[] collabPalette = {#f89540, #fa9d3a, #fca635, #fdb030, #fdb92b, #fdc427, #fcce25, #fad824, #f6e425, #f3ee26};

boolean is3D = false;
PeasyCam camera;

void settings() {
    if (is3D) {
        size(w, h, P3D);
    } else {
        size(w, h);
    }
}

void setup() {
    // load background image
    mapBG = loadImage("mapBG_light.png");
    mapOverlay = loadImage("mapBG_buildings_clean_black.png");

    // load table
    collabTable = loadTable("vis_collaborations.tsv", "header, tsv");
    int n_collabs = collabTable.getRowCount();

    // create array for collab objects
    collabs = new Collaboration[n_collabs];

    // read through table, extract location info, build collaborations array
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

    // animation settings
    if (is3D) {
        camera = new PeasyCam(this, 0, 0, 0, 50);
    }
    noLoop();
    smooth();
}


void draw() {
    background(255); 

    // show map 
    tint(255, 150);
    image(mapBG, 0, 0, width, height);
    tint(255, 255);
    image(mapOverlay, 0, 0, width, height);

    // show all collaborations
    for (Collaboration collab : collabs) {
       collab.display();
    }

    //show some collaborations
    //for (int c = 0; c<1000; c++) {
    //collabs[c].display();
    //}


}

void keyPressed() {
    if (key == 's') {
        save("collabMap.png");
    }
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
        } else if ((totalCollabs >= 1) && (totalCollabs<5)){
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

        // define length of each ctrl pt vector
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
            orthVecRotDeg = 10.0;
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

    // display method
    void display() {
        // draw the connection
        noFill();
        stroke(connColor);
        strokeWeight(1.5);
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

        // show reference lines
        noFill();
        stroke(connColor);
        //line(leftPt_screen.x, leftPt_screen.y, rightPt_screen.x, rightPt_screen.y);
        //stroke(0, 50);
        //line(leftPt_screen.x, leftPt_screen.y, leftPt_ctrl.x, leftPt_ctrl.y);
        //line(rightPt_screen.x, rightPt_screen.y, rightPt_ctrl.x, rightPt_ctrl.y);

        // show dots
        noStroke();
        fill(dotColor);
        ellipse(leftPt_screen.x, leftPt_screen.y, 15, 15);
        ellipse(rightPt_screen.x, rightPt_screen.y, 15, 15);
    }
}