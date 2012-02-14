#import <UIKit/UIKit.h>
#include "testApp.h"
#include "filtersOld.h"


//--------------------------------------------------------------
void testApp::setup(){
//	myFbo = new ofxFBOTexture();
//	myFbo->allocate(320,480, false);
//	myFbo->clear(0,0,0,255);
	//myFbo.clear();
	buttonDown.loadImage("buttonDown.png");
	buttonUp.loadImage("buttonDown.png");
	isButtonDown = false;
	tabort1=0;
	tabort2=0;
	
	senseAudio.init(0.5,0.5*0.001,0.5*0.0001,0.5*0.00001,2/(2.59*44100*60+1),44100);
	senseAcceleration.init(0.5,0.5*0.9,0.5*0.1,0.5*0.1,2/(2.59*20*60+1),20); //0.0006 gives thalf=60s
	senses[0] = &senseAudio;
	senses[1] = &senseAcceleration;
	//different sample times require different parameters. audio: 44kHz. accelerometer: 20 Hz
	//alfa=2/(2.59*fsamp*thalf+1) where fsamp is sampling freq, thalf is time when weigting factor has decreased to half
	//so, say a half time of 10 seconds. that gives alfa=2e-6 for sound and alfa=4e-3 for accelerometer
	
	
	imax=0; //to prevent drawing if drawball called with mode=1 before mode=0;
	radius=1;
	
	//define several servers if one is down
	//urlStringC="http://homeweb.mah.se/~k3bope/contextphoto/upload.php";
	urlStringC="http://asynkronix.se/contextphoto/upload2.php";

	taptreshold=1000;
	showDebug = false;
	phototaken=false;
	photodrawn=false;
	uploaded=true;
	uploadcountdown=0;
	// register touch events
	ofRegisterTouchEvents(this);
	
	// initialize the accelerometer
	ofxAccelerometer.setup();
	
	//iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
	
	cameraPixels = NULL; 
	camera = new ofxiPhoneImagePicker();
	camera->setMaxDimension(480); //otherwise we will have enormous images
	//camera->showCameraOverlay(); //too get rid of preview/use button, but also hides flash and zoom controls...
	
	//some accelerometer vars
	alfaShake=0.05;
	deltaxfilt=0;
	alfadelta=0.001;
		
	
	//sound setup
	//for some reason on the iphone simulator 256 doesn't work - it comes in as 512!
	//so we do 512 - otherwise we crash
	initialBufferSize	= 512;
	sampleRate 			= 44100;
	drawCounter			= 0;
	bufferCounter		= 0;
	
	buffer				= new float[initialBufferSize];
	memset(buffer, 0, initialBufferSize * sizeof(float));
	
	// 0 output channels,
	// 1 input channels
	// 44100 samples per second
	// 512 samples per buffer
	// 4 num buffers (latency)
	ofSoundStreamSetup(0, 1, this, sampleRate, initialBufferSize, 4);
	ofSetFrameRate(20);
	maxSound=0;
	maxSoundFilt=0;
	alfaSound=0.001;
	
	
	gbbackground=255;
	
	
	
	
	
	//photo.loadImage("images/instructions.png");

	
	//Important: small change in original openCamera in ofxiPhoneImagePicker.mm
	//to prevent app from crashing after some pictures.
	//See http://www.openframeworks.cc/forum/viewtopic.php?f=25&t=3249 comment by Lars
	//add line _imagePicker.sourceType = NULL;
	//before _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	//camera->openCamera();
	filtertype = 0;
}


// callback for CGDataProviderCreateWithData
// dirty programming: releaseData is already defined in ofziPhoneExtras.mm 
// but i don't know how to get it in this scope, so i made a releasData2 instead
void releaseData2(void *info, const void *data, size_t dataSize) {
	//	NSLog(@"releaseData\n");
	free((void*)data);		// free the 
}


//--------------------------------------------------------------
void testApp::update()
{

	
	/*coreLocation = new ofxiPhoneCoreLocation();
	hasCompass = coreLocation->startHeading();
	hasGPS = coreLocation->startLocation();*/
	
	//cout << "update " << (tabort1++) << endl;
	if(camera->imageUpdated){
		imagetime=ofGetElapsedTimeMillis();
		int orientation=iPhoneGetOrientation();
		//OFXIPHONE_ORIENTATION_PORTRAIT			UIDeviceOrientationPortrait
		//OFXIPHONE_ORIENTATION_UPSIDEDOWN		UIDeviceOrientationPortraitUpsideDown
		//OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT	UIDeviceOrientationLandscapeRight
		//OFXIPHONE_ORIENTATION_LANDSCAPE_LEFT	UIDeviceOrientationLandscapeLeft
		//not working
		
		
		//second try, not working either... always returning "up"
		int orientation2=camera->getOrientation();
		switch(orientation2)
		{
			case OFX_IMG_PICKER_UP:
				cout<<"up\n";
				break;
			case OFX_IMG_PICKER_DOWN:
				cout<<"down\n";
				break;
			case OFX_IMG_PICKER_LEFT:
				cout<<"left\n";
				break;
			case OFX_IMG_PICKER_RIGHT:
				cout<<"right\n";
				break;
			default:
				cout<<"?\n";
				break;
					
		}
		
		
		
		
		
		
		
		
		
		
		// the pixels seem to be flipped, so let's unflip them: 
		if (cameraPixels == NULL){
			// first time, let's get memory based on how big the image is: 
			cameraPixelsFlip = new unsigned char [camera->width * camera->height*4];
			cameraPixelsRot = new unsigned char [camera->width * camera->height*4];
			cameraPixels = new unsigned char [camera->width * camera->height*4];
		}

		//of sort of assumes portrait
		int width=min(camera->width,camera->height);
		int height=max(camera->width,camera->height);
		ofcvColorImg.allocate(width, height);
		ofcvGrayImg.allocate(width, height);
		ofcvSobelImg.allocate(width, height);
				
		// now, lets flip the image vertically:
		for (int i = 0; i < camera->height; i++){
			memcpy(cameraPixelsFlip+(camera->height-i-1)*camera->width*4, camera->pixels+i*camera->width*4, camera->width*4);
		}


		//if landscape, image should also be rotated 90 degrees
		//this works with the hardware button to the rigth, but will render image upside down with
		//image on the right. can't get iPhoneGetOrientation() working
		if (camera->width>camera->height) {
			int xold,yold,iold;
			for (int y = 0, i=0; y<camera->width; y++){
				for (int x=0; x<camera->height; x++) {
					//x and y are coordinetes in the new pic. i is array index 
					//first calculate coordinates in original picture
					yold=camera->height-x;
					xold=y;
					//then calculate iold
					iold=4*(xold+yold*camera->width);
					cameraPixelsRot[i]=cameraPixelsFlip[iold];
					cameraPixelsRot[i+1]=cameraPixelsFlip[iold+1];
					cameraPixelsRot[i+2]=cameraPixelsFlip[iold+2];
					cameraPixelsRot[i+3]=cameraPixelsFlip[iold+3];
					i+=4;
				}
			}
			memcpy(cameraPixels,cameraPixelsRot,camera->width * camera->height*4);
				
		}
		else {
			memcpy(cameraPixels,cameraPixelsFlip,camera->width * camera->height*4);
		}
		
	
		
		camera->imageUpdated=false;

	//	cout << "width: " << camera->width << ", height: " << camera->height << endl;
		//convert ofImage to opencv-image
		IplImage *cvRGBA;
		IplImage *cvGray;
		IplImage *cvImageTemp;
		cvRGBA = cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 4);
		cvGray = cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 1);
		cvImageTemp = cvCreateImage(cvSize(width,height), IPL_DEPTH_32F, 1);
		

		cvRGBA->imageData = (char*)cameraPixels;
		//cvGray->imageData = (char*)cameraPixels;//probaby not a good idea...
		
		//how can i get the 4 chan data into 1 chan...
		//with of-images i can just say ofcvGrayImg=ofcvColorImg
		//but I can't say cvGray=cvRGBA
		
		
		ofcvColorImg = cvRGBA;

		//time for filtering
		//ofcvColorImg.blur(10);		
		//ofcvColorImg.dilate();	
		int value=10;
		if( value % 2 == 0 ) {
			ofLog(OF_LOG_NOTICE, "in blur, value not odd -> will add 1 to cover your back");
			value++;
		}
		//cvSmooth( cvRGBA, cvImageTemp, CV_BLUR , value);
		//cvRGBA=cvImageTemp;
		//ofcvColorImg=cvRGBA;

		//cvGray=cvRGBA; //does not work, try following code instead:
		
		
		cvCvtColor(cvRGBA,cvGray, CV_RGB2GRAY );
		ofcvGrayImg= cvGray;
		//ofcvGrayImg.blur(20);
		//ofcvGrayImg.threshold(7);

		
		//cout << "cvGray.channels: " << cvGray->nChannels << endl;

		cvSobel(cvGray,cvImageTemp,0,1,3);

		ofcvSobelImg=cvImageTemp;
		
		//contourFinder.findContours(cvGrayImg, 10, (340*240)/3, 10, true);	// find holes

		
		
		//some book keeping to prevent image from being uploaded before it is showed
		//(as a screen grab is uploaded). Also some dirty code to draw some images only once
		phototaken=true;
		photodrawn=false;
		uploaded=false;
		uploadcountdown=5;
		
		
		
	}
	//shake monitor
	oldacc=acc;
	acc=ofxAccelerometer.getRawAcceleration();
	deltaacc2=acc-oldacc;
	//	senseAcceleration.sampling(vectorabs(deltaacc2));//nu deriverar jag acceleration men borde kanske integrera...
	senseAcceleration.sampling(vectorabs(acc)-1); // -1 to compensate for gravity
	//cout << senseAcceleration.valueEnergy << "\n";
	
	//cout<<"valueChange "<<senseAcceleration.valueChange<<"\n";
	
	
	lastsample=sample;
	sample=ofGetElapsedTimeMillis();
	deltat=sample-lastsample;
	v=v+(vectorabs(acc)-1)*deltat/1000;
	//cout<<"v "<<v<<" acc.x "<<acc.x<<" abs(a) "<< vectorabs(acc) << "\n";
	//consoleplot(acc.x, 3, '*');
	//cout << deltat << "\n";
	
	
	
	
	maxacc=filteredMax(maxacc,acc,alfaShake);
	minacc=filteredMin(minacc,acc,alfaShake);
	
	
	deltaacc=maxacc-minacc;
	
	
	//printf("maxx=%2.3f minx=%2.3f deltax=%2.3f \n", maxx,minx,deltax);
	if (deltaacc.x>3) {
		//cout<<"\n\n-xxxxxxxxxxxxxxx-shake detected---------------------" << ofGetElapsedTimeMillis() << "\n\n";
	}
	if (deltaacc.y>3) {
		//cout<<"\n\n-yyyyyyyyyyyyyyy-shake detected---------------------" << ofGetElapsedTimeMillis() << "\n\n";
	}
	if (deltaacc.z>3) {
		//cout<<"\n\n-zzzzzzzzzzzzzzz-shake detected---------------------" << ofGetElapsedTimeMillis() << "\n\n";
	}
	//cout << maxacc.x << " " << minacc.x << "\n";
	//cout << maxacc.x-minacc.x << " " << deltaacc.x << "\n";
	
	deltaxfilt=deltaacc.x*alfadelta+(1-alfadelta)*deltaxfilt;
	//cout << "deltaxfilt " << deltaxfilt << endl;
	
	
 }

//--------------------------------------------------------------
void testApp::draw()
{

	//cout << "draw " << (tabort2++) << endl;
	if (!phototaken) {
		//do nothing on first draw because camera is opened on start
	}
	else {
		//cout << maxSound << endl;
		
		ofSetColor(255,255,255);		
		
		//do filtering based on something
		if (!photodrawn) {
		//	filtertype=ofRandom(0,5);
			cout << "filtertype = " << filtertype << endl;

		}
		
	
		
		//filtertype = 2; // hack by mads
		if (filtertype == 0) /// cute curves
		{
			if (!photodrawn) {
				filterVignette_2(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);
				filterCurves_2(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),senses);
				filterFrameit(ofcvColorImg.getPixels() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);
			}
			ofcvColorImg.draw(0, -61,ofGetWidth(),ofGetHeight());
			photodrawn=true;
		}
		else
		if (filtertype == 1) /// cute curves with hsv
		{
		
			if (!photodrawn)
			{
				filterVignette_2(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);
				cvCvtColor( ofcvColorImg.getCvImage(), ofcvColorImg.getCvImage(), CV_RGB2HSV );
				filterCurves_hsv(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),senses);
				cvCvtColor( ofcvColorImg.getCvImage(), ofcvColorImg.getCvImage(), CV_HSV2RGB );
				filterFrameit(ofcvColorImg.getPixels() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);
			}
			ofcvColorImg.draw(0, -61,ofGetWidth(),ofGetHeight());
			photodrawn=true;	
		}
		else if (filtertype == 2)  // digital clitches
		{
			if (!photodrawn) {
				filterGlitch(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(), senses);
				filterVignette_2(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);	
			
			}
			ofcvColorImg.draw(0, -61,ofGetWidth(),ofGetHeight());
			photodrawn=true;
		}
		else if (filtertype == 3) /// crazy fucked up filter
		{
			if (!photodrawn) 
			{
				filterVignette_2(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);	
				filterCurves_crazy(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),senses);
				filterFrameit(ofcvColorImg.getPixels() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);
			}
			ofcvColorImg.draw(0, -61,ofGetWidth(),ofGetHeight());
			photodrawn=true;
		}
		else if (filtertype == 4) /// ants
		{
			if (!photodrawn) 
			{
				for(int i =0; i < 10;i++)
				{
					ant(ofcvColorImg.getPixels(),ofRandom(0,ofcvColorImg.getWidth()), ofRandom(0,ofcvColorImg.getHeight()),ofRandom(0,2*PI),ofcvColorImg.getWidth(), ofcvColorImg.getHeight(), 8,senses);
				}
				filterVignette_2(ofcvColorImg.getCvImage() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);	
				
				filterFrameit(ofcvColorImg.getPixels() , ofcvColorImg.getWidth(), ofcvColorImg.getHeight(),1);
			}
			ofcvColorImg.draw(0, -61,ofGetWidth(),ofGetHeight());
			photodrawn=true;			
		}
	
		else if (filtertype==5) {
			if (!photodrawn) {
				ofcvColorImg.blur(int(deltaxfilt*20));
			}
			ofcvColorImg.draw(0, 0);
			photodrawn=true;
		} else if (filtertype==6) {
			if (!photodrawn) {
				gbbackground=255-maxSound*255;
				gbbackground=max(gbbackground,0);
				gbbackground=min(gbbackground,255);
				cout << "gbbackground " << gbbackground << "maxSound " << maxSound << endl;
			}
			ofSetColor(255,gbbackground,gbbackground);		
			ofcvGrayImg.draw(0,0);
			photodrawn=true;
		} else if (filtertype==7) {
			if (!photodrawn) {
				radius=maxSound*30.0f+2.0f;
				drawball(0,radius);
				photodrawn=true;
			}
			else {
				drawball(1,radius);
			}
		}  else if (filtertype==8) {
			if (!photodrawn) {
				radius=maxSound*30.0f+2.0f;
				drawrect(0,radius);
				photodrawn=true;
			}
			else {
				drawrect(1,radius);
			}
		}  else if (filtertype==9) {
			if (!photodrawn) {
				radius=maxSound*30.0f+2.0f;
				drawtriang(0,radius);
				photodrawn=true;
			}
			else {
				drawtriang(1,radius);
			}
		} else { //fallback
			ofcvColorImg.draw(0,0);
		}
		//ofcvSobelImg.draw(0,0);
		//contourFinder.draw(0, 0);


		if (uploadcountdown>0) {
			uploadcountdown--;
			if (uploadcountdown==0){
				//upload on some draws after picture is taken and filtered
				cout << "drawing and uploading" << endl;
				uploadPicture(true,true); //MADS: DISABLED UPLOAD... BO enabled. params: savelocal and savecloud
				//cout << "UPLOAD DISABLED!!!" << endl;
			}
			else {
				cout << "first draw before uploading" << endl;
				ofSetColor(128,128,128);
				ofRect(6,ofGetHeight()-30,ofGetWidth()-12,24);
				ofSetColor(255, 255, 255);
				ofDrawBitmapString("uploading", 20, ofGetHeight()-18);
			}
		}
		
		
		
	}
	if(isButtonDown)
	{
		buttonDown.draw(0, ofGetHeight()-buttonUp.getHeight(),ofGetWidth(),buttonUp.getHeight());
		
	}
	else {
		buttonUp.draw(0, ofGetHeight()-buttonUp.getHeight(),ofGetWidth(),buttonUp.getHeight());
	}
	
	if(showDebug)
	{
		drawDebug();
	}
	/*myFbo->begin();
		ofSetColor(0, 90, 170);
		ofCircle(20, 20, 20);
	myFbo->end();
	ofSetColor(255, 255, 255);
	myFbo->draw(0, 0);*/

}

void testApp::drawDebug()
{

	ofSetColor(50, 50, 50,90);
	ofRect(0, 0, ofGetWidth(), ofGetHeight()-buttonUp.getHeight());
	
	
	ofSetColor(0,0,255);
	for (int i = 1; i < initialBufferSize && i<ofGetWidth(); i++){
		ofLine(i-1,50+buffer[i-1]*50.0f,i,50+buffer[i]*50.0f);
	}
	ofSetColor(0,255,0);
	ofLine(0,50-maxSound*50.0f,ofGetWidth(),50-maxSound*50.0f);

	ofSetColor(255, 0, 0);
	
	ofRect(10,100,10,1+senseAudio.valueFast*400);
	ofRect(30,100,10,1+senseAudio.valueSlow*400);
	ofRect(50,100,10,1+senseAudio.valueChange*400);
	ofRect(70,100,10,1+senseAudio.max*400);
	ofRect(90,100,10,1+senseAudio.min*400);
	ofRect(110,100,10,1+senseAudio.valueEnergy*400);
	if(senseAudio.isBeat())
	{
		ofSetColor(0, 0, 255);
		ofRect(130,100,11,120);
	}
	
	ofSetColor(0,255,0);
	ofRect(150,100,10,1+senseAcceleration.valueFast*100);
	ofRect(170,100,10,1+senseAcceleration.valueSlow*100);
	ofRect(190,100,10,1+senseAcceleration.valueChange*100);
	ofRect(210,100,10,1+senseAcceleration.max*100);
	ofRect(230,100,10,1+senseAcceleration.min*100);
	ofRect(250,100,10,1+senseAcceleration.valueEnergy*100);
	if(senseAcceleration.isBeat())
	{
		cout << "********* accelerometer beat detected *************\n";
		ofSetColor(0, 0, 255);
		ofRect(270,100,10,120);
	}
	
	
	//ofRect(270,100,10,1+(vectorabs(acc)-1)*100);
	//ofRect(290,100,10,1+vectorabs(deltaacc2)*100);
	
	
	//debug draw value
	ofSetColor(255, 255, 255);
	char* s = new char[30];
	float f=senseAcceleration.valueEnergy; //put float (or int) for output here
	sprintf(s, "%.4g", f);
	ofDrawBitmapString(s, 20, ofGetHeight()-18);
	
	
	ofSetColor(120, 120, 120);
	ofRect(ofGetWidth()-30, 0, 20, ofGetHeight());
	ofSetColor(255, 255, 255);
	ofRect(ofGetWidth()- 30, filtertype * 20, 20, 20);

	//float f=filtertype; //put float (or int) for output here
	sprintf(s, "%i", filtertype);
	ofSetColor(0,0,0);
	ofDrawBitmapString(s,ofGetWidth()- 30+2, filtertype * 20+12);
	ofSetColor(255,255,255);
	
}


//--------------------------------------------------------------
void testApp::exit() {
}


//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs &touch){
	if(touch.id == 0 && touch.y > ofGetHeight()- buttonUp.getHeight())
	{
		isButtonDown = true;
	}
	
	
	
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs &touch){
//	if(touch.id == 1){
//	}		
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs &touch){	
	if(touch.id == 0 && touch.y > ofGetHeight()- buttonUp.getHeight() && isButtonDown) {
		
		cout << "touch detected" << endl;
		if((ofGetElapsedTimeMillis()-imagetime)>taptreshold){ //too avoid double tap on use button
			//camera->openCamera();
			camera->showCameraOverlay();
			//camera->openCamera()
			cout << "camera opened" << endl;
		}
		else {
			cout << "touch too soon, camera not opened" << endl;
		}
	} 
	if(touch.id == 1)
	{
		showDebug = !showDebug;	
	}
	if(showDebug && touch.x > ofGetWidth()-80 && touch.x < ofGetWidth())
	{
		filtertype = touch.y/20;
		cout << filtertype;
	}
	isButtonDown = false;

}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs &touch){
}

//--------------------------------------------------------------
void testApp::lostFocus() {
}

//--------------------------------------------------------------
void testApp::gotFocus() {
}

//--------------------------------------------------------------
void testApp::gotMemoryWarning() {
}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){
}

void testApp::uploadPicture(bool savelocal,bool savecloud){
	//Grab image with and convert to UIImage
	//slightly modified code from ofxiPhoneExtras.mm to grab image
	CGRect rect = [[UIScreen mainScreen] bounds];
	int width = rect.size.width;
	int height =  rect.size.height;
	NSInteger myDataLength = width * height * 4;
	GLubyte *buffer = (GLubyte *) malloc(myDataLength);
	GLubyte *bufferFlipped = (GLubyte *) malloc(myDataLength);
	glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	for(int y = 0; y <height; y++) {
		for(int x = 0; x <width * 4; x++) {
			bufferFlipped[int((height - 1 - y) * width * 4 + x)] = buffer[int(y * 4 * width + x)];
		}
	}
	free(buffer);	// free original buffer
	
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bufferFlipped, myDataLength, releaseData2);
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);		
	
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);
	
	UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
	CGImageRelease(imageRef);
	
	//3 feb 2011: experiments on local saving by Bo P
	//there is a of method saveimage that probably isnt working, but i'll try...
	//i tried but i couldn't get it working. 
	//or maybe i jsut start with the objective c
	//UIImage* imageToSave = [imageView image]
	//this works perfectly
	if (savelocal){
		UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
	}
	
	
	if (savecloud){
		//Upload image
		NSData *imageData = UIImageJPEGRepresentation(image, 1);
		// setting up the URL to post to
	
		//NSString *urlString = @"http://dvwebb02.mah.se/~k3bope/contextphoto/upload.php";

		NSString *urlString;
		urlString = [NSString stringWithUTF8String: urlStringC];
	
	
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		[request setURL:[NSURL URLWithString:urlString]];
		[request setHTTPMethod:@"POST"];

		/*
		add some header info now
		 we always need a boundary when we post a file
		 also we need to set the content type
	 
		 You might want to generate a random boundary.. this is just the same 
		 as my output from wireshark on a valid html post
		 */
		NSString *boundary = [NSString stringWithString:@"---------------------------14737809831466499882746641449"];
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
		[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
		/*
		 now lets create the body of the post
		 */
		NSMutableData *body = [NSMutableData data];
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];	
		[body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"photogenericuser.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[NSData dataWithData:imageData]];
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		// setting the body of the post to the reqeust
		[request setHTTPBody:body];
		
		// now lets make the connection to the web
		cout << "Uploading to ";
		NSLog(urlString);
		NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
		NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		
		NSLog(returnString);
		cout << "uploaded" << endl;
	}
	
	
}

//--------------------------------------------------------------
void testApp::audioReceived(float * input, int bufferSize, int nChannels){
	
	if( initialBufferSize != bufferSize ){
		ofLog(OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize);
		return;
	}	
	
	float absbuffer;
	// samples are "interleaved"
	for (int i = 0; i < bufferSize; i++){
		buffer[i] = input[i];
		absbuffer=abs(buffer[i]);
		senseAudio.sampling(abs(buffer[i]));
		
		if (absbuffer>maxSound) {
			maxSound=absbuffer;
		}
		else {
			maxSound=absbuffer*alfaSound+(1-alfaSound)*maxSound;
		}
		


						 
	}
	
	
	bufferCounter++;
	
}

	
ofPoint testApp::filteredMax(ofPoint maxacc,ofPoint acc, float alfa){
	ofPoint newmaxacc;
	if (acc.x>maxacc.x) {
		newmaxacc.x=acc.x;
	}
	else {
		newmaxacc.x=acc.x*alfaShake+(1-alfaShake)*maxacc.x;
	}
	if (acc.y>maxacc.y) {
		newmaxacc.y=acc.y;
	}
	else {
		newmaxacc.y=acc.y*alfaShake+(1-alfaShake)*maxacc.y;
	}
	if (acc.z>maxacc.z) {
		newmaxacc.z=acc.z;
	}
	else {
		newmaxacc.z=acc.z*alfaShake+(1-alfaShake)*maxacc.z;
	}
	return newmaxacc;
}

ofPoint testApp::filteredMin(ofPoint minacc,ofPoint acc, float alfa){
	ofPoint newminacc;
	if (acc.x<minacc.x) {
		newminacc.x=acc.x;
	}
	else {
		newminacc.x=acc.x*alfaShake+(1-alfaShake)*minacc.x;
	}
	if (acc.y<minacc.y) {
		newminacc.y=acc.y;
	}
	else {
		newminacc.y=acc.y*alfaShake+(1-alfaShake)*minacc.y;
	}
	if (acc.z<minacc.z) {
		newminacc.z=acc.z;
	}
	else {
		newminacc.z=acc.z*alfaShake+(1-alfaShake)*minacc.z;
	}
	return newminacc;
}

float testApp::vectorabs(ofPoint p){
	return sqrt(p.x*p.x+p.y*p.y+p.z*p.z);
}


void testApp::consoleplot(float x,float max,char c){
	int width=80;
	float scale=width/2/max;
	int i=0;
	int plot=width/2+scale*x;
	for (i=0;i<plot;i++){
		cout << " ";
	}
	cout << c;
	for (int j=0;j<width-i;j++){
		cout << " ";
	}
	cout << x << "\n";
}

	
