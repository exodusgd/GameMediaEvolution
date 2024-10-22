import processing.sound.*;

// Class that represents a type of storage media
class SMedia {

  int capacity, maxDrawAmount = 0;
  PImage image;

  SMedia (PImage i, int c) {
    this.image = i;
    this.capacity = c;
  }

  void setMaxDrawAmount(int value)
  {
    this.maxDrawAmount = value;
  }
}

// Class used to create a slider
class Slider {
  float xOffset, handleMinX, handleMaxX;
  float sliderValue = 0;
  PVector sliderSize, handleSize, sliderPos, handlePos;
  boolean isHovered, isLocked, playedHoverSound = false;

  Slider(float pX, float pY, float sW, float sH, float hW, float hH)
  {
    this.sliderPos = new PVector(pX, pY);
    this.sliderSize = new PVector(sW, sH);
    this.handlePos = new PVector(this.sliderPos.x-this.sliderSize.x/2 + this.sliderValue * this.sliderSize.x, this.sliderPos.y);
    this.handleSize = new PVector(hW, hH);

    this.handleMinX = this.sliderPos.x-this.sliderSize.x/2;
    this.handleMaxX = this.sliderPos.x+this.sliderSize.x/2;
  }

  void drawSlider()
  {
    noStroke();
    rectMode(CENTER);
    fill(219, 196, 172);
    rect(
      this.sliderPos.x, this.sliderPos.y,
      this.sliderSize.x+0.02*height + this.handleSize.x, this.sliderSize.y+0.02*height,
      2
      );
    fill(64, 49, 42);
    rect(
      this.sliderPos.x, this.sliderPos.y,
      this.sliderSize.x + this.handleSize.x, this.sliderSize.y
      );
  }

  void drawSliderHandle()
  {
    if (abs(mouseX - this.handlePos.x) < this.handleSize.x/2 && abs(mouseY - this.handlePos.y) < this.handleSize.y/2) {
      fill(252, 48, 3);
      this.isHovered = true;

      // Play hovered sound
      if (!this.playedHoverSound)
      {
        this.playedHoverSound = true;
        hoverSFX.play();
      }
    } else {
      fill(205, 54, 21);
      this.isHovered = false;
      this.playedHoverSound = false;
    }


    this.handlePos = new PVector(this.sliderPos.x-this.sliderSize.x/2 + this.sliderValue * this.sliderSize.x, this.sliderPos.y);

    if (this.handlePos.x < handleMinX) {
      this.handlePos.x = handleMinX;
    }

    if (this.handlePos.x > handleMaxX) {
      this.handlePos.x = handleMaxX;
    }

    // Draw handle
    rectMode(CENTER);
    noStroke();
    rect(this.handlePos.x, this.handlePos.y, this.handleSize.x, this.handleSize.y);
    fill(40, 40, 40, 120);
    rect(this.handlePos.x, this.handlePos.y, this.handleSize.x*0.1, this.handleSize.y);
  }

  void setIsLocked(boolean value)
  {
    this.isLocked = value;
  }

  void setXOffset(float value)
  {
    this.xOffset = value;
  }

  void setValue(float value)
  {
    if (value > 1)
    {
      this.sliderValue = 1;
      return;
    }
    if (value < 0)
    {
      this.sliderValue = 0;
      return;
    }
    this.sliderValue = value;
  }
}


// ------------------------ GLOBAL VARIABLES ------------------------
// Size of the window where storage media can be drawn (initialized in setup)
PVector sMediaWindowSize;

// Position of the miniature images displaying the previous and next media to be displayed
PVector currentMediaMiniaturePos;
PVector nextMediaMiniaturePos;
// Scale to draw the miniatures at (in relation to the maximum draw size)
float miniatureScale = 0.24;

// Objects to store info on each storage media type (initialized in setup)
SMedia spectrum;
SMedia nes;
SMedia snes;
SMedia n64;
SMedia ps1;
SMedia dvd;
SMedia bluray;

// Stores the currently drawn media (updated in runtime)
SMedia currentMedia;
// Array with the storage media ordered by capacity (initialized in setup)
SMedia[] mediaByCapacity;
// Stores the array index of the currently drawn media
int currentMediaIndex = 0;
// Stores the amount of images drawn in the last frame (used to play the line pass SFX)
int lastDrawAmount = 1;

// Slider used to change capacity
Slider capacitySlider;

// The woodgrain image used for the background
PImage woodBGImg;

// Sounds
SoundFile hoverSFX;
SoundFile linePassSFX;

// ------------------------ FUNCTIONS ------------------------
// Calculates the size at which each image will be drawn
PVector calculateImageSize(PImage img, int imgCols, int imgRows)
{
  float imgWidth = img.width;
  float imgHeight = img.height;
  float imgRatio = imgWidth/imgHeight;

  // Make image size fill either width or height based on ratio
  if (imgCols > imgRows)
  {
    imgWidth = sMediaWindowSize.x*0.9/imgCols;
    imgHeight = imgWidth/imgRatio;
    if (imgHeight*imgRows > sMediaWindowSize.y*0.9)
    {
      imgHeight = sMediaWindowSize.y*0.9/imgRows;
      imgWidth = imgHeight*imgRatio;
    }
  } else
  {
    imgHeight = sMediaWindowSize.y*0.9/imgRows;
    imgWidth = imgHeight*imgRatio;
    if (imgHeight*imgCols > sMediaWindowSize.x*0.9)
    {
      imgWidth = sMediaWindowSize.x*0.9/imgCols;
      imgHeight = imgWidth/imgRatio;
    }
  }
  return new PVector (imgWidth, imgHeight);
}

// ------------------------------------------------ SETUP ------------------------------------------------
void setup()
{
  size(1280, 720);
  sMediaWindowSize = new PVector(width*0.6, height*0.6);

  // Load the background image
  woodBGImg = loadImage("wood_background.jpg");

  // Initialize sound
  hoverSFX = new SoundFile(this, "hover.wav");
  hoverSFX.amp(0.6f);
  linePassSFX = new SoundFile(this, "line_pass.wav");
  linePassSFX.amp(0.3f);

  // Load images of the various video game storage media
  PImage spectrumTapeImg = loadImage("ChuckieEgg_Tape.png");
  PImage nesCartridgeImg = loadImage("mario_bros_cartridge.png");
  PImage snesCartridgeImg = loadImage("snes_cartridge.png");
  PImage n64CartridgeImg = loadImage("mario64_cartridge.png");
  PImage ps1DiscImg = loadImage("ffvii_disc.png");
  PImage ps2DiscImg = loadImage("sotc_dvd.png");
  PImage ps3DiscImg = loadImage("lastofus_disc.png");

  // Initialize the storage media with the respective storage capacities
  bluray = new SMedia(ps3DiscImg, 52428800); // 50GB
  dvd = new SMedia(ps2DiscImg, 8912896); // 8.5GB
  ps1 = new SMedia(ps1DiscImg, 675840); // 660MB
  n64 = new SMedia(n64CartridgeImg, 65536); // 64MB
  snes = new SMedia(snesCartridgeImg, 6144); // 6MB
  nes = new SMedia(nesCartridgeImg, 1024); // 1MB
  spectrum = new SMedia(spectrumTapeImg, 48); // 48KB

  // Set the starting media to the zx spectrum tape
  currentMedia = spectrum;
  currentMediaIndex = 0;

  // Store the storage media by capacity
  mediaByCapacity = new SMedia[]
    {
    spectrum,
    nes,
    snes,
    n64,
    ps1,
    dvd,
    bluray
  };

  // Set max draw amount for each media based on its relation with the capacity of the following media
  int mediaIndex = 0;
  for (SMedia media : mediaByCapacity)
  {
    if (mediaIndex >= mediaByCapacity.length-1)
    {
      media.setMaxDrawAmount(14);
    } else {
      media.setMaxDrawAmount(mediaByCapacity[mediaIndex+1].capacity/media.capacity);
      mediaIndex++;
    }
  }

  // Create the capacity slider
  capacitySlider = new Slider(
    width/2, height*0.925, // slider pos
    width*0.7, height*0.04, // slider size
    height*0.09, height*0.04); // handle size

  // Set the padding between the miniature and the capacity slider
  float miniatureOffset = width * 0.09;
  // Initialize the position of the current and next media miniature images
  currentMediaMiniaturePos = new PVector(capacitySlider.sliderPos.x - capacitySlider.sliderSize.x/2 - miniatureOffset, height*0.925);
  nextMediaMiniaturePos = new PVector(capacitySlider.sliderPos.x + capacitySlider.sliderSize.x/2 + miniatureOffset, height*0.925);
}

// ------------------------------------------------ DRAW ------------------------------------------------
void draw()
{
  background(255);

  int totalImgsToDraw = int(map(capacitySlider.sliderValue, 0, 1, 1, currentMedia.maxDrawAmount+1));

  // Check whether the drawn image should change
  if (capacitySlider.sliderValue >= 0.99 && currentMediaIndex < mediaByCapacity.length-1)
  {
    currentMediaIndex++;
    currentMedia = mediaByCapacity[currentMediaIndex];
    totalImgsToDraw = 1;
    capacitySlider.setIsLocked(false);
    capacitySlider.sliderValue = 0.05;
  } else if (capacitySlider.sliderValue <= 0.01 && currentMediaIndex > 0) {
    currentMediaIndex--;
    currentMedia = mediaByCapacity[currentMediaIndex];
    totalImgsToDraw = currentMedia.maxDrawAmount;
    capacitySlider.setIsLocked(false);
    capacitySlider.sliderValue = 0.95;
  }

  if (totalImgsToDraw < 1) {
    totalImgsToDraw = 1;
  }

  if (totalImgsToDraw != lastDrawAmount && !linePassSFX.isPlaying())
  {
    linePassSFX.play();
  }

  // ------------------------ DRAW IMAGES ------------------------

  // Calculate the position of the first image to draw
  float initialOffsetY = height/11;

  int imgCols = 1;
  int imgRows = 1;

  if (sqrt(totalImgsToDraw) > int(sqrt(totalImgsToDraw)))
  {
    imgCols = int(sqrt(totalImgsToDraw) + 1);
    imgRows = int(sqrt(totalImgsToDraw));
  } else {
    imgCols = imgRows = int(sqrt(totalImgsToDraw));
  }

  if (imgCols*imgRows < totalImgsToDraw)
  {
    if (currentMediaIndex > 3) {
      imgCols++;
    } else {
      imgRows++;
    }
  }

  // Save draw amount
  lastDrawAmount = totalImgsToDraw;

  PVector imgSize = calculateImageSize(currentMedia.image, imgCols, imgRows);
  PVector imgPos = new PVector (width/2 - imgCols*imgSize.x/2, height/2 - imgRows*imgSize.y/2 - initialOffsetY);

  // ------------------------ DRAW TV ------------------------
  // Draw the woodgrain background
  image(woodBGImg, 0, 0);

  // Draw reference image
  //PImage tvRef = loadImage("tv_ref.jpg");
  //image(tvRef, width/2 - tvRef.width/2*1.7, -10, tvRef.width*1.7, tvRef.height*1.45);

  // Points to draw the tv screen shape
  PVector p1 = new PVector(
    width/2 - height/2 - height*0.02,
    height*0.12);
  PVector p2 = new PVector(
    width/2,
    height*0.07);
  PVector p3 = new PVector(
    width/2 + height/2 + height*0.02,
    height*0.12);
  PVector p4 = new PVector(
    width/2 + height/2 + height*0.075,
    height*0.42);
  PVector p5 = new PVector(
    width/2 + height/2 + height*0.02,
    height*0.70);
  PVector p6 = new PVector(
    width/2,
    height*0.76);
  PVector p7 = new PVector(
    width/2 - height/2 - height*0.02,
    height*0.70);
  PVector p8 = new PVector(
    width/2 - height/2 - height*0.075,
    height*0.42);
  PVector p9 = p1;
  //PVector[] points = {p1, p2, p3, p4, p5, p6, p7, p8, p9};

  // Control points to draw the tv screen shape
  PVector c1 = new PVector(
    width/2 - height/2 + height*0.03,
    height*0.08);
  PVector c2 = new PVector(
    width/2 - height/2 + height*0.12,
    height*0.07);
  PVector c3 = new PVector(
    width/2 + height/2 - height*0.12,
    height*0.07);
  PVector c4 = new PVector(
    width/2 + height/2 - height*0.03,
    height*0.08);
  PVector c5 = new PVector(
    width/2 + height/2 + height*0.067,
    height*0.170);
  PVector c6 = new PVector(
    width/2 + height/2 + height*0.07,
    height*0.21);
  PVector c7 = new PVector(
    width/2 + height/2 + height*0.07,
    height*0.63);
  PVector c8 = new PVector(
    width/2 + height/2 + height*0.08,
    height*0.64);
  PVector c9 = new PVector(
    width/2 + height/2 - height*0.04,
    height*0.75);
  PVector c10 = new PVector(
    width/2 + height/2 - height*0.07,
    height*0.76);
  PVector c11 = new PVector(
    width/2 - height/2 + height*0.07,
    height*0.76);
  PVector c12 = new PVector(
    width/2 - height/2 + height*0.04,
    height*0.75);
  PVector c13 = new PVector(
    width/2 - height/2 - height*0.08,
    height*0.64);
  PVector c14 = new PVector(
    width/2 - height/2 - height*0.07,
    height*0.63);
  PVector c15 = new PVector(
    width/2 - height/2 - height*0.07,
    height*0.21);
  PVector c16 = new PVector(
    width/2 - height/2 - height*0.067,
    height*0.170);
  //PVector[] controlPoints =
  //  {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16};

  // Draw the tv screen proper
  strokeWeight(0.05*height);
  stroke(26);
  fill(191, 232, 211);
  beginShape();
  vertex(p1.x, p1.y);
  bezierVertex(
    c1.x, c1.y,
    c2.x, c2.y,
    p2.x, p2.y);
  bezierVertex(
    c3.x, c3.y,
    c4.x, c4.y,
    p3.x, p3.y);
  bezierVertex(
    c5.x, c5.y,
    c6.x, c6.y,
    p4.x, p4.y);
  bezierVertex(
    c7.x, c7.y,
    c8.x, c8.y,
    p5.x, p5.y);
  bezierVertex(
    c9.x, c9.y,
    c10.x, c10.y,
    p6.x, p6.y);
  bezierVertex(
    c11.x, c11.y,
    c12.x, c12.y,
    p7.x, p7.y);
  bezierVertex(
    c13.x, c13.y,
    c14.x, c14.y,
    p8.x, p8.y);
  bezierVertex(
    c15.x, c15.y,
    c16.x, c16.y,
    p9.x, p9.y);
  endShape();

  float initialImgPosX = imgPos.x;

  int drawnImgs = 0;

  for (int i = 0; i < imgRows; i++)
  {
    for (int j = 0; j < imgCols; j++)
    {
      if (drawnImgs < totalImgsToDraw)
      {
        image(currentMedia.image, imgPos.x, imgPos.y, imgSize.x, imgSize.y);
        imgPos.x += imgSize.x;
        drawnImgs++;
      }
    }
    imgPos.x = initialImgPosX;
    imgPos.y += imgSize.y;
  }

  // ------------------------ DRAW SLIDER ------------------------
  capacitySlider.drawSlider();

  for (int i = 0; i <= currentMedia.maxDrawAmount; i++)
  {
    stroke(219, 196, 172, 120);
    strokeWeight(height*0.005);
    line(
      capacitySlider.sliderPos.x - capacitySlider.sliderSize.x/2 + i*capacitySlider.sliderSize.x/currentMedia.maxDrawAmount, // start x
      capacitySlider.sliderPos.y - capacitySlider.sliderSize.y/2, // start y
      capacitySlider.sliderPos.x - capacitySlider.sliderSize.x/2 + i*capacitySlider.sliderSize.x/currentMedia.maxDrawAmount, // end x
      capacitySlider.sliderPos.y + capacitySlider.sliderSize.y/2  // end y
      );
  }

  capacitySlider.drawSliderHandle();

  // ------------------------ DRAW MINIATURES ------------------------
  PImage currentMediaImg = currentMedia.image;
  PVector miniatureSize = calculateImageSize(currentMediaImg, 1, 1);
  // Scale down the image to miniature scale
  miniatureSize.x *= miniatureScale;
  miniatureSize.y *= miniatureScale;

  image(
    currentMediaImg,
    currentMediaMiniaturePos.x - miniatureSize.x/2, currentMediaMiniaturePos.y - miniatureSize.y/2,
    miniatureSize.x, miniatureSize.y
    );

  if (currentMediaIndex < mediaByCapacity.length - 1) {
    PImage nextMediaImg = mediaByCapacity[currentMediaIndex + 1].image;
    miniatureSize = calculateImageSize(nextMediaImg, 1, 1);
    // Scale down the image to miniature scale
    miniatureSize.x *= miniatureScale;
    miniatureSize.y *= miniatureScale;

    image(
      nextMediaImg,
      nextMediaMiniaturePos.x - miniatureSize.x/2, nextMediaMiniaturePos.y - miniatureSize.y/2,
      miniatureSize.x, miniatureSize.y);
  }

  // ------------------------ DRAW TEXT ------------------------
  String labelText = "";
  String capacityText = "";

  String[] sizeUnits = {"KB", "MB", "GB", "TB", "PB", "EB"};
  int sizeUnitIndex = 0;

  float totalCapacity = float(currentMedia.capacity) * float(totalImgsToDraw);

  while (totalCapacity >= 1024)
  {
    totalCapacity/=1024;
    sizeUnitIndex++;
  }

  String unitText = " " + sizeUnits[sizeUnitIndex];
  capacityText = nf(totalCapacity, 0, 2) + unitText;

  PFont spectrumFont = createFont("zx-spectrum.ttf", 128);
  textFont(spectrumFont);

  // Draw capacity text
  fill(0);
  textAlign(CENTER);
  textSize(42);
  text(capacityText, width/2, height - height*0.14);

  // Draw label text
  fill(0);
  textAlign(LEFT);
  textSize(24);
  text(labelText, 40, height-10);
}

// Slider controls
void mousePressed() {
  if (capacitySlider.isHovered) {
    capacitySlider.setIsLocked(true);
    capacitySlider.setXOffset(mouseX-capacitySlider.handlePos.x);
  }
}
void mouseDragged() {
  if (capacitySlider.isLocked) {
    capacitySlider.setValue(map(mouseX-capacitySlider.xOffset, capacitySlider.handleMinX, capacitySlider.handleMaxX, 0, 1));
  }
}
void mouseReleased() {
  capacitySlider.setIsLocked(false);
}
