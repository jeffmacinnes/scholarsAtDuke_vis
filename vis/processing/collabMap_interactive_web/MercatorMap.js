// adapted from https://github.com/chriswhong/sickweather/blob/master/NBC/MercatorMap.pde
// Mercator Mapping class with functions for converting between geo and screen coords
// Instantiate the object using degrees for the lat/lon bounds of the map
function MercatorMap(w, h, latN, latS, lonW, lonE){
  this.w = w;
  this.h = h;
  this.latN = latN;
  this.latS = latS;
  this.lonW = lonW;
  this.lonE = lonE;
  
  // convert lat and lon values
  this.latN_relative = log(tan(this.latN / 360*PI + PI / 4));
  this.latS_relative = log(tan(this.latS / 360*PI + PI / 4));
  this.lonW_radians = radians(this.lonW);
  this.lonE_radians = radians(this.lonE);
  
  // helper functions /////////////////////////////////////
  // convert a geo vector (i.e. lat/lon) to screen coords
  this.getScreenLocation = function(geoVector){
    var lat = geoVector.x;
    var lon = geoVector.y;
    
    var screenX = this.getScreenX(lon);
    var screenY = this.getScreenY(lat);
    
    var screenVector = createVector(screenX, screenY)
    return screenVector;
  }
  
  // get the screen X coord for a given longitude
  this.getScreenX = function(lon){
    var lon_radians = radians(lon)
    var screenX = this.w * (lon_radians - this.lonW_radians) / (this.lonE_radians - this.lonW_radians);
    return screenX;
  }
  
  // get the screen Y coord for a given latitude
  this.getScreenY = function(lat){
    var latRelative =  log(tan(lat / 360*PI + PI / 4));
    var screenY = this.h * (latRelative - this.latN_relative) / (this.latS_relative - this.latN_relative);
    return screenY;
  }

}
