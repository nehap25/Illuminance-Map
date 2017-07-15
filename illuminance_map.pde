import java.util.HashMap;
import java.util.Iterator; 
import java.util.Map; 
Table table; 
final float lampheight = 7.6; 
//coefficients for Gaussian equation that models the G(theta) = g1 - g2*e^(-g3(theta - g4)^2)
float g1 = 1.491; 
float g2 = 1.122; 
float g3 = 0.0003; 
int g4 = 0; 
float g5x = 0.015; 
float g5y = 0.015; 
int m = 6; 
float thetapx = 23*PI/180; 
float thetapy = 51.5*PI/180; 
MercatorMap mercatormap; 
HashMap <PVector, Float> lumens; 
int rowCount; 

void setup(){
  noStroke();
  initMap();
  mercatorMap = new MercatorMap(width, height, CanvasBox().get(0).x, CanvasBox().get(1).x, CanvasBox().get(0).y, CanvasBox().get(1).y, 0);
  initGraphics(); 
  size(displayWidth-50, displayHeight-100, P3D);
  drawLights(lights);
}

void draw(){
  mercatorMap = new MercatorMap(width, height, CanvasBox().get(0).x, CanvasBox().get(1).x, CanvasBox().get(0).y, CanvasBox().get(1).y, 0);
  noStroke();
  fill(0, 150);
  map.draw();
  image(lights, 0, 0);
}


PGraphics lights;
PShape lightcone;
ArrayList<PVector> polepositions = new ArrayList<PVector>();
ArrayList<PVector> lightshape = new ArrayList<PVector>();

void drawLights(PGraphics p){
  table = loadTable("lightnodes.csv", "header"); 
  rowCount = table.getRowCount(); 
  
  polepositions = determineLocations(table, mercatorMap); 
  lightshape = determineEndpoints(table, 0, mercatorMap); 
  lumens = determineLuminance(lightshape, lightcone); 
  float pixelspermeter = 1/(mercatorMap.Haversine(mercatorMap.getGeo(new PVector(0, 0)), mercatorMap.getGeo(new PVector(1, 1))));
  lightcone = createShape();
  lightcone.beginShape();
  for (PVector lumen: lumens.keySet()) {
    float val = lumens.get(lumen);
    float m = map(val, 0.0, 1.0, 0.0, 255);  
    fill(m); 
    strokeWeight(1); 
    lightcone.vertex(lumen.x, lumen.y); 
  }
  lightcone.endShape();
  p.beginDraw();
  for (int j = 0; j < polepositions.size(); j ++)  {
          p.shape(lightcone, polepositions.get(j).x, polepositions.get(j).y);
          p.fill(0); 
          p.noStroke();
    }
   //draws heat map 
    
    p.endDraw();
 
    polepositions.clear(); 
    lumens.clear();
}


//determines the endpoints of the luminance shape 
ArrayList<PVector> determineEndpoints (Table table, int rowNumber, MercatorMap mercatorMap) {
   ArrayList<PVector> endpoints = new ArrayList<PVector>(); 
  // float metersperpixel = mercatorMap.Haversine(mercatorMap.getGeo(new PVector(1, 2)), mercatorMap.getGeo(new PVector(1, 3)));
   float metersperpixel = metersPerPixel();
//   print(metersperpixel);
   endpoints.clear(); 
   PVector pt = new PVector(0,0);
   for (int i = 1; i <= 360; i ++) {
     float maxAngle = PI/2 - atan(tan(thetapx)*tan(thetapy)/pow(pow(tan(thetapx)*sin(i*PI/180) , m)+ pow(tan(thetapy)*cos(i*PI/180) , m), 1/m)); 
     float x = lampheight * tan(maxAngle) * cos(i*PI/180) / metersperpixel; 
     float y = lampheight * tan(maxAngle) * sin(i*PI/180) / metersperpixel; 
//     float maxAngle = PI/3;
//    float thing = atan(tan(thetapx)*tan(thetapy)/pow(pow(tan(thetapx)*sin(i*PI/180) , m)+ pow(tan(thetapy)*cos(i*PI/180) , m), 1/m)); 
//    println(thing);
//     float x = (lampheight * tan(maxAngle) * cos(i*PI/180)) / metersperpixel; 
//     float y = (lampheight * tan(maxAngle) * sin(i*PI/180)) / metersperpixel; 
     PVector newPt = new PVector(pt.y + y, pt.x + x); 
     endpoints.add(newPt);    
   }
   return endpoints;  
   
}  

ArrayList<PVector> determineLocations (Table table, MercatorMap mercatorMap){
  ArrayList<PVector> locs = new ArrayList<PVector>();
  for (int i = 0; i < table.getRowCount(); i++){
      PVector loc = mercatorMap.getScreenLocation(new PVector(table.getFloat(i, "y"), table.getFloat(i, "x")));
      locs.add(loc);
  }
  return locs;
}

boolean inPolygon(PShape shape, PVector point){
    int num = shape.getVertexCount();
    int i = num - 1;
    int j = i;
    boolean contains = false;
    
    for (i = 0; i < num; i++){
      PVector vi = shape.getVertex(i);
      PVector vj = shape.getVertex(j);
         
        if(vi.y < point.y && vj.y >= point.y || vj.y < point.y && vi.y >= point.y){
            if (vi.x + (point.y - vi.y) / (vj.y - vi.y) * (vj.x - vi.x) < point.x){
               contains=!contains;
            }
          }
      j=i;
    }
    return contains;
}
//creates bounding box and assigns each PVector a luminance 
HashMap<PVector, Float> determineLuminance(ArrayList<PVector> endpoints, PShape shape) {
  HashMap<PVector, Float> lumens  = new HashMap<PVector, Float>(); 
  float metersperpixel = mercatorMap.Haversine(mercatorMap.getGeo(new PVector(0, 0)), mercatorMap.getGeo(new PVector(1, 1)));
  ArrayList<PVector> points = new ArrayList<PVector>(); 
  double minX = Double.POSITIVE_INFINITY; 
  double maxX = Double.NEGATIVE_INFINITY; 
  double minY = Double.POSITIVE_INFINITY; 
  double maxY = Double.NEGATIVE_INFINITY; 
  for (PVector endpoint: endpoints) {
    if (endpoint.x < minX) {
      minX = endpoint.x;
    }
    else if (endpoint.x > maxX) {
      maxX = endpoint.x;
    }
    else if (endpoint.y < minY) {
      minY = endpoint.y;
    }
    else if (endpoint.y > maxY) {
      maxY = endpoint.y; 
    }
  }
  int minx = (int)(minX); 
  int maxx = (int)(maxX); 
  int miny = (int)(minY); 
  int maxy = (int)(maxY); 
  for (int i = minx; i <= maxx; i ++) {
    for (int j = miny; j <= maxy; j ++) {
      PVector pt = new PVector(i, j); 
      if (inPolygon(shape, pt)) {
        points.add(pt); 
      }
      
    }
    
  }
  for (PVector point: points) {
       float denom = pow(point.x*metersperpixel, 2) + pow(point.y*metersperpixel, 2) + pow(lampheight, 2); 
       float theta = acos(lampheight/sqrt(denom));
       float I = g1 - g2*exp(-g3 * pow(g4 - theta, 2)); 
       float luminance = I*lampheight/pow((pow(point.x*metersperpixel, 2) + pow(point.y*metersperpixel, 2) + pow(lampheight, 2)), 3/2); 
       lumens.put(point, luminance); 
  }
  return lumens; 
}


void mouseDragged(){
  mercatorMap = new MercatorMap(width, height, CanvasBox().get(0).x, CanvasBox().get(1).x, CanvasBox().get(0).y, CanvasBox().get(1).y, 0);
  lights.clear();
  drawLights(lights);
}

void keyPressed(){
  switch (key) {
    case ' ':
      println(mercatorMap.getGeo(new PVector(mouseX, mouseY)));
  }
  
}
