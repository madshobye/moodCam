#pragma once
#include "ofxOpenCv.h"
#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"

class testApp : public ofxiPhoneApp {
	
public:
	void setup();
	void update();
	void draw();
	void exit();
	
	void touchDown(ofTouchEventArgs &touch);
	void touchMoved(ofTouchEventArgs &touch);
	void touchUp(ofTouchEventArgs &touch);
	void touchDoubleTap(ofTouchEventArgs &touch);
	
	void lostFocus();
	void gotFocus();
	void gotMemoryWarning();
	void deviceOrientationChanged(int newOrientation);
	

	//variables
	unsigned char * cameraPixels;	// the camera image needs to be flipped, so we'll use this memory for that. 
	ofxiPhoneImagePicker * camera;
	ofImage	photo;
	ofPoint imgPos;
	ofxCvColorImage  tmpImg;// = new ofxCvColorImage();
	bool phototaken;

	
};

