#pragma once
#include "ofxOpenCv.h"
#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "senseMaker.h"
#include "filters.h"

//#include "ofxFBOTexture.h"



class testApp : public ofxiPhoneApp {
	
public:
	
//	ofxFBOTexture * myFbo;

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
	
	void uploadPicture(bool savelocal,bool saveglobal);
	int DetectShake();

	senseMaker senseAudio;
	void audioReceived( float * input, int bufferSize, int nChannels );
	ofPoint filteredMax(ofPoint maxacc,ofPoint acc, float alfa);
	ofPoint filteredMin(ofPoint minacc,ofPoint acc, float alfa);
	float vectorabs(ofPoint p);
	void consoleplot(float x,float max,char c);



	
	void drawball(int mode,int radius);
	void drawrect(int mode,int radius);
	void drawtriang(int mode,int radius);
	void myTriangle(int x, int y, int rotation, int r);
	void drawDebug();
	
	//variables
	unsigned char * cameraPixelsFlip;	// the camera image needs to be flipped, so we'll use this memory for that. 
	unsigned char * cameraPixelsRot;	// the camera image sometimes needs to be rotated, so we'll use this memory for that. 
	unsigned char * cameraPixels;
	ofxiPhoneImagePicker * camera;
	ofImage	photo;
	ofPoint imgPos;
	ofxCvColorImage  ofcvColorImg;
	bool phototaken;
	bool photodrawn;
	bool uploaded;
	int uploadcountdown; 
	

	ofxCvGrayscaleImage					ofcvGrayImg;
	
	ofxCvContourFinder					contourFinder;
	ofxCvFloatImage			ofcvSobelImg;
	int tabort1;
	int tabort2;
	bool hasCompass;
	bool hasGPS;
	ofxiPhoneCoreLocation * coreLocation;
	
	
	int imagetime;
	int taptreshold;
	
	//accelerometer vars
	senseMaker senseAcceleration;
	senseMaker * senses[2];
	ofPoint oldacc,acc,maxacc,minacc,deltaacc,deltaacc2;
	float alfaShake;
	float alfadelta;
	float deltaxfilt;
	int sample,lastsample,deltat;
	float v;
	
	
	//sound vars
	int		initialBufferSize;
	int		sampleRate;
	int		drawCounter, bufferCounter;
	float	maxSound,minSound;
	float	maxSoundFilt;
	float	alfaSound;
	float 	* buffer;
	
	//Sensemaking vars
	float audio_slow;
	float audio_fast;
	
	
	int gbbackground;
	
	int filtertype;
	
	//upload vars
	char * urlStringC;
	
	//drawball vars
	int imax;	
	int pixelArray[500*500];
	int radiusoffsetArray[500*500];
	int rotationArray[500*500];
	int radius; //ful global variabel
	bool showDebug;
	
	ofImage buttonDown;
	ofImage buttonUp;
	bool isButtonDown;
	

	
};

