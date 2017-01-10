
var latMax = 36.0114604043;
var latMin = 35.9908939;
var lonMax = -78.906105;
var lonMin = -78.946954607;

var w = 1056;
var h = 720;

var bg;
var table;
collabs = [];


function preload(){
  table = loadTable("assets/collaborations_sample.tsv", "tsv", "header");
  bg = loadImage("assets/map.png");
}

function setup() {
  
  createCanvas(w, h);
  
  // read through table, extract location info, build collaborations array
  for (var r=0; r < table.getRowCount(); r++){
    var srcLon  = float(table.getString(r, 'src_LON'));
    var dstLon = float(table.getString(r, 'dst_LON'));
    var srcLat = float(table.getString(r, 'src_LAT'));
    var dstLat = float(table.getString(r, 'dst_LAT'));
    
    // create new collaboration instance with this info
    collabs[r] = new Collaboration(srcLon, srcLat, dstLon, dstLat)
  }
  

  
  //show background
  background(120);
  tint(255, 100);
  image(bg, 0, 0);
  
  noLoop();
  
}


function draw() {
  background(190);
  smooth();
 
  // display every collaboration
  for (var c=0; c<1000; c++){
    collabs[c].display();    
  }

  
}

//*************** CLASSES
function Collaboration(x1, y1, x2, y2){

  // convert coordinates to canvas dimensions, order so x1 is always to the left
  if (x1 <= x2){
    this.x1 = map(x1, lonMin, lonMax, 0, w);
    this.y1 = map(y1, latMin, latMax, h, 0);
    this.x2 = map(x2, lonMin, lonMax, 0, w);
    this.y2 = map(y2, latMin, latMax, h, 0);
  } else {
    this.x1 = map(x2, lonMin, lonMax, 0, w);
    this.y1 = map(y2, latMin, latMax, h, 0);
    this.x2 = map(x1, lonMin, lonMax, 0, w);
    this.y2 = map(y1, latMin, latMax, h, 0);
  }
  var srcPt = createVector(this.x1, this.y1);
  var dstPt = createVector(this.x2, this.y2)
  
  // define the color for this connection
  //var connColor = color(random(255), random(255), random(255), 100)
  var connColor = color(220, 120, 24, 100);
  
  // calculate the distance between pts
  var collabDist = srcPt.dist(dstPt);
  
  // vector describing the connection between src and dst pts
  var connVec = p5.Vector.sub(srcPt, dstPt)
  connVec.normalize(); // set vector to length 1
  
  // vector orthogonal to connection
  var orthVec = connVec.rotate(HALF_PI);
  
  // define length of bezier curve control point vectors (perpendicular to anchor pts)
  var ctrlOffset = map(random(), 0, 1, 1, 1.1);     // add some randomness to the length so arcs don't all overlap
  var ctrlVecLen = .5 * collabDist * ctrlOffset;
  
  //***** define location of bezier curve control points *****************************
  // create distinct copies of the orthogonal vector for src and dst points  
  var src_orthVec = orthVec.copy();   
  var dst_orthVec = orthVec.copy();
  
  // rotate the src control vector cw and the dst control ccw by same amount
  var orthVecRotDeg = 20 //*noise(random());   // deg to rotate control pt vectors in by
  src_orthVec.rotate(radians(orthVecRotDeg)); // rotate src orthVec cw 
  dst_orthVec.rotate(radians(360-orthVecRotDeg));

  // define the control points for both src and dst control vectors
  var srcCtrlPt = createVector(srcPt.x + src_orthVec.x * ctrlVecLen, srcPt.y + src_orthVec.y * ctrlVecLen);
  var dstCtrlPt = createVector(dstPt.x + dst_orthVec.x * ctrlVecLen, dstPt.y + dst_orthVec.y * ctrlVecLen);
  
  // display function
  this.display = function(){

    // draw the connection
    noFill();
    stroke(connColor);
    bezier(srcPt.x, srcPt.y, srcCtrlPt.x, srcCtrlPt.y, dstCtrlPt.x, dstCtrlPt.y, dstPt.x, dstPt.y);
    
    // draw reference lines
    noFill();
    stroke(0, 50);
    //line(srcPt.x, srcPt.y, dstPt.x, dstPt.y);           // straight connection
    //line(srcPt.x, srcPt.y, srcCtrlPt.x, srcCtrlPt.y);   // src control pt
    //line(dstPt.x, dstPt.y, dstCtrlPt.x, dstCtrlPt.y);   // dst control pt
    
    // show dots at locations
    fill(255);
    noStroke();
    ellipse(srcPt.x, srcPt.y, 10, 10);
    ellipse(dstPt.x, dstPt.y, 10, 10);
  }
  
}


