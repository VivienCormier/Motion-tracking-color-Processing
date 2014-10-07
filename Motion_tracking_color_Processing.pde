// Learning Processing
// Daniel Shiffman
// http://www.learningprocessing.com

// Example 16-13: Simple motion detection

import processing.video.*;
import java.util.HashMap;
import java.util.Map;

// Variable for capture device
Capture video;
// How different must a pixel be to be a "motion" pixel
float threshold = 50;
// Color detection
color detectColor = color(39, 114, 86);

void setup() {
  size(320, 240);
  video = new Capture(this, width, height, 30);
  video.start();
}

void draw() {

  // Capture video
  if (video.available()) {
    video.read();
  }

  loadPixels();
  video.loadPixels();

  int[] detectedPixels;
  detectedPixels = new int[video.width * video.height];

  // Begin loop to walk through every pixel
  for (int x = 0; x < video.width; x ++ ) {
    for (int y = 0; y < video.height; y ++ ) {

      int loc = x + y*video.width;            // Step 1, what is the 1D pixel location
      color current = video.pixels[loc];      // Step 2, what is the current color

      // Step 4, compare colors (previous vs. current)
      float r1 = red(current); 
      float g1 = green(current); 
      float b1 = blue(current);
      float r2 = red(detectColor); 
      float g2 = green(detectColor); 
      float b2 = blue(detectColor);
      float diff = dist(r1, g1, b1, r2, g2, b2);

      pixels[loc] = current;

      // Step 5, How different are the colors?
      // If the color at that pixel has changed, then there is motion at that pixel.
      if (diff > threshold) { 
        // If motion, display black
//        pixels[loc] = current;
        detectedPixels[loc] = 0;
      } else {
        // If not, display white
//        pixels[loc] = color(0, 0, 255);
        detectedPixels[loc] = 1;
      }
    }
  }
  
  updatePixels();
  
  optimizeDetection(detectedPixels);
  
//  updatePixels();
  
}

void optimizeDetection(int[] detectedPixels) {

  int incrementIdArea = 1;
  HashMap <Integer, AreaDetected> araesDetected = new HashMap();
  HashMap <Integer, PixelDetected> allPixelsDetected = new HashMap();

  for (int x = 0; x < detectedPixels.length; x ++ ) {
  
    if ( detectedPixels[x] == 1 ) {

      int idArea = 0;
      
      PixelDetected pixelX = allPixelsDetected.get(x);
      
      if (pixelX != null) {
        
        idArea = pixelX.idArea;
        
      } else {
        
        if ( x-1 >= 0 && x % video.width != 0 && (x - 1) % video.width != 0 ) {

          PixelDetected pixelTop = allPixelsDetected.get(x-1 * video.width);
          if (pixelTop != null) {
            idArea = pixelTop.idArea;
          } else {
  
            PixelDetected pixelLeft = allPixelsDetected.get(x-1);
            if (pixelLeft != null) {
              idArea = pixelLeft.idArea;
            } else {
              AreaDetected area = new AreaDetected(incrementIdArea);
              araesDetected.put(incrementIdArea, area);
              idArea = incrementIdArea;
              incrementIdArea++;
            }
          }
          
          PixelDetected pixelDetected = new PixelDetected(x, idArea);
          allPixelsDetected.put(x, pixelDetected);
          AreaDetected area = araesDetected.get(idArea);
          area.addPixel(pixelDetected);
          
        } 
      }
      
      if (idArea != 0) {
        // Set value area around
        
        // top left
        addValueAround(detectedPixels, allPixelsDetected, araesDetected, (x - 1)-1 * video.width, idArea);
        // top
        addValueAround(detectedPixels, allPixelsDetected, araesDetected, x-1 * video.width, idArea);
        // top right
        addValueAround(detectedPixels, allPixelsDetected, araesDetected, (x + 1) -1 * video.width, idArea);
        //right
        addValueAround(detectedPixels, allPixelsDetected, araesDetected, x + 1, idArea);
        // bottom right
        addValueAround(detectedPixels, allPixelsDetected, araesDetected, (x + 1 ) +1 * video.width, idArea);
        // bottom
        addValueAround(detectedPixels, allPixelsDetected, araesDetected, x+1 * video.width, idArea);
        // bottom left
        addValueAround(detectedPixels, allPixelsDetected, araesDetected, (x - 1)+1 * video.width, idArea);
      }

    }
  }

  int idAreaMax = 0;
  int numberAreaMax = 0;
  
  for (Map.Entry me : araesDetected.entrySet ()) {
    int idArea = (Integer) me.getKey();
    AreaDetected area = araesDetected.get(idArea);
    if ( area.pixelsArea.size() > numberAreaMax ) {
      idAreaMax = area.idArea;
      numberAreaMax = area.pixelsArea.size();
    }
  }
  
  if (numberAreaMax > 50 ) {
    
    AreaDetected areaDetectedColor = araesDetected.get(idAreaMax);
    if ( areaDetectedColor != null) {
      PixelDetected firstPixelDetectedColor = areaDetectedColor.pixelsArea.get(0);
      int xFirst = firstPixelDetectedColor.loc % video.width;
      int yFirst = Math.round(firstPixelDetectedColor.loc / video.width);
      int minX = xFirst,minY = yFirst,maxX = xFirst,maxY = yFirst;
      for (PixelDetected pixelDetectedColor : areaDetectedColor.pixelsArea) {
        int x = pixelDetectedColor.loc % video.width;
        int y = Math.round(pixelDetectedColor.loc / video.width);
         
        pixels[pixelDetectedColor.loc] = color(0, 255, 0);
         
        if (x < minX) {
          minX = x; 
        }
        if (y < minY) {
          minY = y; 
        }
        if (x > maxX) {
          maxX = x; 
        }
        if (y > maxY) {
          maxY = y; 
        }
        
      }
      
      ellipse(minX + (maxX-minX)/2,minY + (maxY-minY)/2,50,50);
      loadPixels();
      
    }
  }
  
}

void addValueAround (int[] detectedPixels, HashMap <Integer, PixelDetected> allPixelsDetected, HashMap <Integer, AreaDetected> araesDetected, int loc, int idArea) {
  
  if (loc >= 0 && loc < detectedPixels.length) {
    if ( loc % video.width != 0 && (loc - 1) % video.width != 0 ) {
      if (detectedPixels[loc] == 1) {
        PixelDetected pixel = allPixelsDetected.get(loc);
        AreaDetected area = araesDetected.get(idArea);
        if (pixel == null) {
          PixelDetected pixelDetected = new PixelDetected(loc, idArea);
          allPixelsDetected.put(loc, pixelDetected);
          area.addPixel(pixelDetected);
        } else {
          AreaDetected areaToDelete = araesDetected.get(pixel.idArea);
          
          if (areaToDelete != area) {
            for (PixelDetected pixelToDelete : areaToDelete.pixelsArea) {
              PixelDetected pixelToMove = new PixelDetected(pixelToDelete.loc, idArea);
              allPixelsDetected.remove(pixelToDelete.loc);
              allPixelsDetected.put(pixelToMove.loc, pixelToMove);
              area.addPixel(pixelToMove);
            }
            araesDetected.remove(pixel.idArea);
          }
          
        }
      } 
    }
  }
  
}

public class PixelDetected {

  public int loc;
  public int idArea;

  public PixelDetected(int startLoc, int startIdArea) {
    loc = startLoc;
    idArea = startIdArea;
  }
}

public class AreaDetected {

  public ArrayList<PixelDetected> pixelsArea;
  public int idArea;

  public AreaDetected(int startIdArea) {
    idArea = startIdArea;
    pixelsArea = new ArrayList<PixelDetected>();
  }

  public void addPixel(PixelDetected pixel) {
    pixelsArea.add(pixel);
  }
  
}

