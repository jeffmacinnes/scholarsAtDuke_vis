// extent of the map coverage
var latN = 36.0146;
var latS = 35.9890;
var lonE = -78.9008;
var lonW = -78.9513;

// canvas dimensions
var w = 1000;
var h = 627;

// mercator mapping instance
var mercatorMap

var mapBG;
var collabTable;
collabs = [];

function preload(){
  collabTable = loadTable("assets/vis_collaborations_sample.tsv", "tsv", "header")
  mapBG = loadImage("assets/mapBG_light_small.png");
}

function setup() {
  createCanvas(w,h);
  mercatorMap = new MercatorMap(w, h, latN, latS, lonW, lonE);
  console.log(mercatorMap.w);
  
  // read through table, extract location info, build collaboration array
  for (var r=0; r < collabTable.getRowCount(); r++){
    var srcLon  = float(collabTable.getString(r, 'a1_LON'));
    var dstLon = float(collabTable.getString(r, 'a2_LON'));
    var srcLat = float(collabTable.getString(r, 'a1_LAT'));
    var dstLat = float(collabTable.getString(r, 'a2_LAT'));
    var totalCollabs = int(collabTable.getString(r, 'totalCollabs'));
    
    // add this collaboration to the collabs array
    var srcPt = createVector(srcLat, srcLon);
    var dstPt = createVector(dstLat, dstLon);
    collabs[r] = new Collaboration(srcPt, dstPt, totalCollabs);
  }
  
}

function draw() {
  background(255);
  image(mapBG);
  
  // loop through all collaborations
  for (var c=0; c<collabs.length; c++){
    collabs[c].display();
  }
  
}


//********** CLASSES *****************
function Collaboration(srcPt_geo, dstPt_geo, totalCollabs){
  this.srcPt_geo = srcPt_geo;
  this.dstPt_geo = srcPt_geo;
  this.totalCollabs = totalCollabs;
  console.log(srcPt_geo.x);
  
  // convert locations from geo (lat/lon) to screen (x,y)
  if (srcPt_geo.y <= dstPt_geo.y) {
    this.leftPt_screen = mercatorMap.getScreenLocation(srcPt_geo);
    this.rightPt_screen = mercatorMap.getScreenLocation(dstPt_geo);
  } else {
    this.leftPt_screen = mercatorMap.getScreenLocation(dstPt_geo);
    this.rightPt_screen = mercatorMap.getScreenLocation(srcPt_geo);
  }
  console.log(this.leftPt_screen.x);
  this.connColor = color(255, 0, 0);
  
  
  this.display = function(){
    fill(this.connColor)
    ellipse(this.leftPt_screen.x, this.leftPt_screen.y, 10, 10);
    
  }
  
}


