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
var mapTitle;
var mapBuildings;
var collabTable;
collabs = [];
var buildingTable;
buildings = [];

var collabPalette = {color1:'#DBC954', color2:'#DF611D', color3:'#CE3136'};


function preload() {
	collabTable = loadTable("assets/vis_collaborations.tsv", "tsv", "header");
	buildingTable = loadTable("assets/buildingNames.tsv", "tsv", "header");
	mapBG = loadImage("assets/mapBG_light_small.png");
	mapTitle = loadImage("assets/title_overlay.png");
	mapBuildings = loadImage("assets/mapBG_buildings_clean_black_small.png");
	blFont = loadFont("assets/ITCAvantGardeBOLD.ttf");
}

function setup() {
	createCanvas(w, h); // or P2D
	mercatorMap = new MercatorMap(w, h, latN, latS, lonW, lonE);
	console.log(mercatorMap.w);

	// text parameters
	textFont("Courier")
	textSize(14);

	// read through collabs table, extract location info, build collaboration array
	for (var r = 0; r < collabTable.getRowCount(); r++) {
		var srcLon = float(collabTable.getString(r, 'a1_LON'));
		var dstLon = float(collabTable.getString(r, 'a2_LON'));
		var srcLat = float(collabTable.getString(r, 'a1_LAT'));
		var dstLat = float(collabTable.getString(r, 'a2_LAT'));
		var totalCollabs = int(collabTable.getString(r, 'totalCollabs'));

		// add this collaboration to the collabs array
		var srcPt = createVector(srcLat, srcLon);
		var dstPt = createVector(dstLat, dstLon);
		collabs[r] = new Collaboration(srcPt, dstPt, totalCollabs);
	}

	// read through buildings table, create buildings array
	for (var b = 0; b < buildingTable.getRowCount(); b++) {
		var blLon = float(buildingTable.getString(b, 'LON'));
		var blLat = float(buildingTable.getString(b, 'LAT'));
		var blName = buildingTable.getString(b, 'NAME');

		// add this point to building array
		blPt = createVector(blLat, blLon);
		buildings[b] = new Building(blPt, blName);
	}

}

function draw() {
	background(255);
	tint(255, 190);
	image(mapBG);
	tint(255, 255);
	image(mapBuildings);
	image(mapTitle);

	// loop through all collaborations
	for (var c = 0; c < collabs.length; c++) {
		collabs[c].update();
		collabs[c].display();
	}

	// show all building dots
	for (var b = 0; b < buildings.length; b++) {
		buildings[b].update();
		buildings[b].displayDot();
	}

	// show any building names
	for (var b = 0; b < buildings.length; b++) {
		buildings[b].displayName();
	}

}


function colorAlpha(aColor, alpha){
	var c = color(aColor);
	return color('rgba(' + [red(c), green(c), blue(c), alpha].join(',') + ')');
}


//********** CLASSES *****************
function Collaboration(srcPt_geo, dstPt_geo, totalCollabs) {
	this.srcPt_geo = srcPt_geo;
	this.dstPt_geo = srcPt_geo;
	
	// set the min mouse distance in order to show this collaboration
	this.minMouseDist = 7;
	this.showConnection = false;

	// convert locations from geo (lat/lon) to screen (x,y)
	if (srcPt_geo.y <= dstPt_geo.y) {
		this.leftPt_screen = mercatorMap.getScreenLocation(srcPt_geo);
		this.rightPt_screen = mercatorMap.getScreenLocation(dstPt_geo);
	} else {
		this.leftPt_screen = mercatorMap.getScreenLocation(dstPt_geo);
		this.rightPt_screen = mercatorMap.getScreenLocation(srcPt_geo);
	}

	// set color
	if (totalCollabs == 1) {
		this.connColor = colorAlpha('#dbc954', 120);
	} else if ((totalCollabs >= 1) && (totalCollabs < 5)) {
		this.connColor = colorAlpha('#DF611D', 120);
	} else {
		this.connColor = colorAlpha('#ce3136', 120);
	}

	// calculate distance between points
	var collabDist = this.leftPt_screen.dist(this.rightPt_screen)

	// vector describing straight line bweteen points
	var connVec = p5.Vector.sub(this.leftPt_screen, this.rightPt_screen);
	connVec.normalize();

	// vector orthogonal to straight line connection
	var orthVec = connVec.copy();
	orthVec.rotate(HALF_PI);

	// define length of each ctrl pt vector
	var maxOffset = 1.1;
	var ctrlVecLen = collabDist * .2 * map(random(0, 1), 0, 1, 1, maxOffset);
	
	// create ctrl point vectors
	var orthVecRotDeg = random(0,50);	// orth vec will be 90deg + this value
	var leftPt_orthVec = orthVec.copy();
	leftPt_orthVec.rotate(radians(orthVecRotDeg));
	leftPt_orthVec.mult(ctrlVecLen);		// set vec length
	var rightPt_orthVec = orthVec.copy();
	rightPt_orthVec.rotate(radians(360-orthVecRotDeg))
	rightPt_orthVec.mult(ctrlVecLen)
	
	// define where the bezier curve control points will be
	this.leftPt_ctrl = p5.Vector.add(this.leftPt_screen, leftPt_orthVec);
	this.rightPt_ctrl = p5.Vector.add(this.rightPt_screen, rightPt_orthVec);


	// update method - determine if mouse is close to this connection vector
	this.update = function() {
		var mouse2leftPt_dist = dist(this.leftPt_screen.x, this.leftPt_screen.y, mouseX, mouseY);
		var mouse2rightPt_dist = dist(this.rightPt_screen.x, this.rightPt_screen.y, mouseX, mouseY);
		if ((mouse2leftPt_dist <= this.minMouseDist) || (mouse2rightPt_dist <= this.minMouseDist)){
			this.showConnection = true;
		} else {
			this.showConnection = false;
		}
		
	}

	// display the connection, if applicable
	this.display = function() {
		if (this.showConnection){
			noFill();
			stroke(this.connColor);
			bezier(this.leftPt_screen.x, this.leftPt_screen.y, 
          		this.leftPt_ctrl.x, this.leftPt_ctrl.y, 
          		this.rightPt_ctrl.x, this.rightPt_ctrl.y, 
          		this.rightPt_screen.x, this.rightPt_screen.y);
		}
	}

}


function Building(blPt_geo, blName) {

	this.blName = blName;
	this.minMouseDist = 7;
	this.showBuilding = false;
	this.dotColor = color('#71B8B8');

	// convert building pt from geo (lat/lon) to screen (x,y)
	this.blPt_screen = mercatorMap.getScreenLocation(blPt_geo);

	// Update - based on mouse distance
	this.update = function() {
		var mouseDist = dist(this.blPt_screen.x, this.blPt_screen.y, mouseX, mouseY);
		if (mouseDist <= this.minMouseDist) {
			this.showBuilding = true;
		} else {
			this.showBuilding = false;
		}
	}

	// Display - building dot
	this.displayDot = function() {
		noStroke();
		// set color based on mouse distance
		if (this.showBuilding) {
			fill(255, 0, 0);
		} else {
			fill(this.dotColor);
		}
		ellipse(this.blPt_screen.x, this.blPt_screen.y, 7, 7);
	}

	// Display - building name
	this.displayName = function() {
		if (this.showBuilding) {

			var textBoxWidth = textWidth(this.blName);
			var textBoxHeight = 25;


			var xOffset = 20;
			fill(255, 200);

			// if mouse on left half...
			if (mouseX < width / 2) {
				textAlign(LEFT, BOTTOM);
				rect(mouseX + xOffset - 5, mouseY - textBoxHeight, textBoxWidth + 10, textBoxHeight)

				// show text
				fill(50);
				text(this.blName, mouseX + xOffset, mouseY);


				// else if mouse on right half...
			} else {
				textAlign(RIGHT, BOTTOM);
				rect(mouseX - textBoxWidth - xOffset - 5, mouseY - textBoxHeight, textBoxWidth + 10, textBoxHeight);

				// show text
				fill(50);
				text(this.blName, mouseX - xOffset, mouseY);
			}
		}
	}
}