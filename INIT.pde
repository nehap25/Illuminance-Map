/*

*/

void initMap(){

  map = new UnfoldingMap(this, new OpenStreetMap.OpenStreetMapProvider());
  MapUtils.createDefaultEventDispatcher(this, map);
  Location Boston = new Location(42.366035, -71.07952);
  map.zoomAndPanTo(Boston, 17);
  println("MAP init");
}

void initGraphics(){
  lights = createGraphics(width, height);
  println("Graphic init");
}
