#import <UIKit/UIKit.h>
#include "testApp.h"




int threadedUpload::count=0;


//--------------------------------------------------------------
void testApp::setup(){	
    ofBackground(0,0,0); 
    //cassette animation
    wheel[0].loadImage("images/hjul0.png");
    wheel[1].loadImage("images/hjul10.png");
    wheel[2].loadImage("images/hjul20.png");
    wheel[3].loadImage("images/hjul30.png");
    wheel[4].loadImage("images/hjul40.png");
    wheel[5].loadImage("images/hjul50.png");
    cassette.loadImage("images/cassette-md-emptywheel-noalpha.png");
    wi=0;
    angle=0;
    
    instaicon.loadImage("images/instamatic3.png");
    
        
    
    //this might be useful to keep music playing in locked mode
    //void interruptionListenerCallback(void *inClientData, UInt32 inInterruptionState) {  
    //    NSLog(@"interruptionListenerCallback");  
    //}
    //this is to keep music playing in locked mode
    //and woyoyoy! it works!
    OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
    //OSStatus result = AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, ofxiPhoneGetAppDelegate());  
    //both OSStatus result... seem to work equally well. The second
    //needs interruptionListenerCallback above uncommented
    UInt32 category = kAudioSessionCategory_PlayAndRecord; //used to be kAudioSessionCategory_MediaPlayback; but the output disables input
    //and it works great with headphones, but without headphones, the earpiece instead of speaker is used for output.
    //does it work with headphones without mic? yes
    result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);  

    
    /*following code makes speaker sound out, even if headphones are connected which is not what I want
    UInt32 audioRouteOverride = 'spkr';   
    AudioSessionSetProperty (         
                             'ovrd',  
                             sizeof (audioRouteOverride),  
                             &audioRouteOverride           
                             );  
     */

    

    
    AudioSessionSetActive(YES);

    
    
    chune.loadSound("sounds/suelta-la-voz.caf");
	chune.setVolume(1.0f);
	chune.setMultiPlay(false);
    //chune.play();    
    chunepaused=true;
    chuneposition=0;
    
	buttonDown.loadImage("buttonDown.png");
	buttonUp.loadImage("buttonDown.png");
	isButtonDown = false;
		
	senseAudio.init(0.5,0.5*0.001,0.5*0.0001,0.5*0.00001,2/(2.59*44100*60+1),44100);
	senseAcceleration.init(0.5,0.5*0.9,0.5*0.1,0.5*0.1,2/(2.59*20*60+1),20); //0.0006 gives thalf=60s
	senses[0] = &senseAudio;
	senses[1] = &senseAcceleration;
	//different sample times require different parameters. audio: 44kHz. accelerometer: 20 Hz
	//alfa=2/(2.59*fsamp*thalf+1) where fsamp is sampling freq, thalf is time when weigting factor has decreased to half
	//so, say a half time of 10 seconds. that gives alfa=2e-6 for sound and alfa=4e-3 for accelerometer
	
    imagetime=0;
 	taptreshold=1000;
	showDebug = false;
	phototaken=false;
	photodrawn=false;
	uploadcountdown=0;

	
    // register touch events
	ofRegisterTouchEvents(this);
	
	// initialize the accelerometer
	ofxAccelerometer.setup();
	
	//iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
	
	camera = new ofxiPhoneImagePicker();
    cameramode=0;
    //0: open camera with preview
    //1: open camera without preview
    //2: open camera without preview, alt 2. 
    //3: open camera without preview, alt 3. 
    if (cameramode==1) {
        //open camera without preview
        camera->showCameraOverlay();
    }
    
	camera->setMaxDimension(480); //480 otherwise we will have enormous images
    
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
	
	//Important: small change in original openCamera in ofxiPhoneImagePicker.mm
	//to prevent app from crashing after some pictures.
	//See http://www.openframeworks.cc/forum/viewtopic.php?f=25&t=3249 comment by Lars
	//add line _imagePicker.sourceType = NULL;
	//before _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	//camera->openCamera();
	filtertype = 0;
}

//--------------------------------------------------------------
void testApp::update()
{
    if(camera->imageUpdated){
		imagetime=ofGetElapsedTimeMillis();
		int orientationA=iPhoneGetOrientation();
		//OFXIPHONE_ORIENTATION_PORTRAIT			UIDeviceOrientationPortrait
		//OFXIPHONE_ORIENTATION_UPSIDEDOWN		UIDeviceOrientationPortraitUpsideDown
		//OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT	UIDeviceOrientationLandscapeRight
		//OFXIPHONE_ORIENTATION_LANDSCAPE_LEFT	UIDeviceOrientationLandscapeLeft
		//not working
   	
		//second try, not working either... always returning "up"
		int orientationB=camera->getOrientation();
        
		
        int orientationC=[UIDevice currentDevice].orientation;
        //cout << "orientation, try 3: " << orientation << endl;
		//ok, this works, but might return value when "use" is clicked, not when photo taken. can be used as qualified guess, 
        //but largest value of width and height must also be used to determine orientation of photo

        
        cout << "orientation A: " << orientationA << ", orientation B: " << orientationB << ", orientation C " << orientationC << endl;
        
        
        
        
        
        
		if (cameraPixelsNoAlpha == NULL){
			// first time, let's get memory based on how big the image is: 
			//cameraPixelsFlip = new unsigned char [camera->width * camera->height*4];
			//cameraPixelsRot = new unsigned char [camera->width * camera->height*4];
			//cameraPixels = new unsigned char [camera->width * camera->height*4];
            cameraPixelsNoAlpha = new unsigned char [camera->width * camera->height*3];
		}
                
        int width=camera->width;
        int height=camera->height;
        
        cout << "width: " << width << endl;
        cout << "height: " << height << endl;
        cout << "window width: " << ofGetWidth() << endl;
        cout << "window height: " << ofGetHeight() << endl;
        drawImage.clear();
        drawImage.allocate(width, height);
        
        unsigned long now=dis(0,"");        
        //delete alphachannel
        for (int i=0,j=0;i<width*height*4;i+=4){
            memcpy(cameraPixelsNoAlpha+j,camera->pixels+i,3);
            j+=3;
        }
        dis(now,"removal of alphachannel");
        
		//time for filtering
        //to start with, for the filters to work with, we have the image drawImage of type ofxCvColorImage
        //and when we are ready we should have the filtered image back in drawImage (drawn) but
        //we also need the filtered image in uploadImage (uploaded)
        

      
        //filtertype=5;
        if (filtertype==0) {
            //no filter
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
        } else if (filtertype==1) {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            //uploadImage=cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 3); maybe this isn't needed???
            now=dis(0,"");
            uploadImage=drawImage.getCvImage();
            now=dis(now,"filter step 1");
            filterCurves_2(uploadImage, drawImage.getWidth(), drawImage.getHeight(),senses); //amount should be affected by senses
            now=dis(now,"filter step 2");
            //Note the the function will alter uploadImage, and that this will also alter drawImage as intended            
        } else if (filtertype==2) {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            now=dis(0,"");
            uploadImage=drawImage.getCvImage();
            now=dis(now,"filter step 1");
            filterCurves_hsv(uploadImage, drawImage.getWidth(), drawImage.getHeight(),0.5); //amount should be affected by senses
            now=dis(now,"filter step 2");
            //Note the the function will alter uploadImage, and that this will also alter drawImage as intended            
        } else if (filtertype==3) {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            now=dis(0,"");
            uploadImage=drawImage.getCvImage();
            now=dis(now,"filter step 1");
            filterVignette_2(uploadImage, drawImage.getWidth(), drawImage.getHeight(),-1);
            now=dis(now,"filter step 2");
            //Note the the function will alter uploadImage, and that this will also alter drawImage as intended            

        } else if (filtertype==4) {
            //this often crashes
            for(int i =0; i < 10;i++)
            {
                cout << "ant iteration " << i << endl;
                ant(cameraPixelsNoAlpha,ofRandom(0,drawImage.getWidth()), ofRandom(0,drawImage.getHeight()),ofRandom(0,2*PI),drawImage.getWidth(), drawImage.getHeight(), 8,0.5);
            }     
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
        } else if (filtertype==5) {
/*            uploadImage=cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 3);
            filterFrameit(drawImage.getPixels() , drawImage.getWidth(), drawImage.getHeight(),-1);
            uploadImage=drawImage.getCvImage(); //very very strange. if portrait mode, original and not filtered image copied to uploadImage
            //but correct filtered image drawn by drawImage.draw. weird. maybe because of documented bug in getPixels ofxCVimage.cpp
            //try getCvROIImage...
  */          
            //new try
            filterFrameit(cameraPixelsNoAlpha,camera->width,camera->height,-1);            
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
            //yes, this was the way to do it. 
            //but must find a way to do it if appying two filters, one with pixels, one with iplimage...
            //no problem if working with pixels before iplimage, but maybe problem if working with
            //pixels after iplimage.  how to get pixels from iplimage???
    
        } else if (filtertype==6) {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
            
        } else if (filtertype==7) {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
            
        } else if (filtertype==8) {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
            
        } else if (filtertype==9) {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
            
        } else {
            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            uploadImage=drawImage.getCvImage();
            
        }

        
        /*
        {
            now=dis(0,"");
            //convert ofxcvcolorImage to opencv-image (IplImage)
            uploadImage = cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 3);
            now=dis(now,"fast: time to filter step 1");
            cvImageTemp = cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 3);
            now=dis(now,"fast: time to filter step 2");
            uploadImage=drawImage.getCvImage();
            now=dis(now,"ultrafast: time to filter step 3");
            int value=0; 
            value=(value/2)*2+1; //value must be odd, this line makes sure it is odd
            cout << "value " << value << endl;
            cvSmooth(uploadImage, cvImageTemp, CV_BLUR , value);
            now=dis(now,"slow: time to filter step 4");
            uploadImage=cvImageTemp;
            now=dis(now,"ultrafast: time to filter step 5");
            drawImage=uploadImage; //works, and seems to be safe
            now=dis(now,"medium: time to filter step 6");
		}
         */
        
        
        
        
        camera->imageUpdated=false;
		phototaken=true;
		photodrawn=false;
		
        //upload filtered photo
        int i=0;
        bool success=false;
        while(!success && i<numberOfUploadThreads){
            if (!tup[i].isThreadRunning()){
                tup[i].upload(uploadImage);
                success=true;
            }
            i++;
        }
        if (!success){
            NSLog(@"%@",@"couldn't upload, all threads running");
        }
	}

    
    //upload status
    /*
    bool uploadthreadrunning=false;
    for (int i=0;i<numberOfUploadThreads;i++){
        if (tup[i].isThreadRunning()) {
            uploadthreadrunning=true;
        }
    }
    if (uploadthreadrunning) {
        for (int i=0;i<numberOfUploadThreads;i++){
            if (tup[i].isThreadRunning()) {
                cout << "r"; 
            }
            else {
                cout << "n";
            }    
        }
        cout << threadedUpload::count << " ";
    }
    */
    
	//shake monitor
	oldacc=acc;
	acc=ofxAccelerometer.getRawAcceleration();
	deltaacc2=acc-oldacc;
    //senseAcceleration.sampling(vectorabs(deltaacc2));//nu deriverar jag acceleration men borde kanske integrera...
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
		cout<<"\n\n-xxxxxxxxxxxxxxx-shake detected---------------------" << ofGetElapsedTimeMillis() << "\n\n";
	}
	if (deltaacc.y>3) {
		cout<<"\n\n-yyyyyyyyyyyyyyy-shake detected---------------------" << ofGetElapsedTimeMillis() << "\n\n";
	}
	if (deltaacc.z>3) {
		cout<<"\n\n-zzzzzzzzzzzzzzz-shake detected---------------------" << ofGetElapsedTimeMillis() << "\n\n";
	}
	//cout << maxacc.x << " " << minacc.x << "\n";
	//cout << maxacc.x-minacc.x << " " << deltaacc.x << "\n";
	
	deltaxfilt=deltaacc.x*alfadelta+(1-alfadelta)*deltaxfilt;
	//cout << "deltaxfilt " << deltaxfilt << endl;
	
	

	
}

void testApp::draw()
{
    //too many scale calculations done in draw. Should be done once in setup
    if (!phototaken) {
        ofSetColor(255,100,0);//red for debugging purposes
        ofRect(0, 0, ofGetWidth(), ofGetHeight());
	}
	else {
        float drawHeight;
        float drawWidth;
        ofSetColor(255,255,255);
        //ofSetColor(127+127*sin(ofGetElapsedTimeMillis()/200), 127+127*sin(ofGetElapsedTimeMillis()/200+PI*2/3), 127+127*sin(ofGetElapsedTimeMillis()/200+PI*4/3));
        if (drawImage.width>drawImage.height) {
            //rotated, landscape pic
            ofPushMatrix();
            ofRotate(90);
            ofTranslate(0, -ofGetWidth());
            drawHeight=ofGetWidth();
            drawWidth=drawImage.width*drawHeight/drawImage.height;
            drawImage.draw(0, 0,drawWidth,drawHeight);
            ofPopMatrix();

        } else {
            drawWidth=ofGetWidth();
            drawHeight=drawImage.height*drawWidth/drawImage.width;
            drawImage.draw(0, 0,drawWidth,drawHeight);            
        }
        photodrawn=true;

    }

    if (!chunepaused && !chune.getIsPlaying()) {
        cout << "end of chune reached. " << chune.getPosition() << " " << chune.getPosition()-1 << endl;
        chunepaused=true;
        chuneposition=0;
    }

    
    
    //the cassette image is 299x192 px and scaled down to 105x67px
    //this scaling could be done once in photoshop instead to save some calculations
    //the instamatic icon i 161x96 px scaled down to 113x67 px. could also be 'shopped. 
    //finally, the square to the right is maybe 320-105-113=102 px if instamaic next to cassette,
    //but seems like instamatic drawn in center instead. doesn't really matter. 
    // (320/3=106,7)
    
    float scale=0.35;
    int cx=0;
    int cy=ofGetHeight()-cassette.getHeight()*scale;
    
    float progress=chune.getPosition();
    if (chunepaused) {
        progress=chuneposition;
    }
    if (!chunepaused) {
        wi++;if (wi>5) wi=0;
    }

    ofSetColor(200,200,200);
    drawCassette(cx,cy,scale,progress,wi);
    
    //draw instamatic icon
    scale=0.7;

    instaicon.draw(ofGetWidth()/2-instaicon.getWidth()/2*scale,ofGetHeight()-instaicon.getHeight()*scale,instaicon.getWidth()*scale,instaicon.getHeight()*scale);

    
    //draw rectangle (to be substituted with something useful
    ofRect(ofGetWidth()/2-instaicon.getWidth()/2*scale+instaicon.getWidth()*scale,ofGetHeight()-instaicon.getHeight()*scale,ofGetWidth()-(ofGetWidth()/2-instaicon.getWidth()/2*scale+instaicon.getWidth()*scale+1)+1,instaicon.getHeight()*scale);
    
    //temporary progress indicator
    //if chune.stop() is called, chune.getPostion() returns 1 but if chune reaches end and stops, chune.getPosition() returns 0
    char* s = new char[30];
    sprintf(s, "%.3f %.2f", chune.getPosition(),chuneposition); 
    ofPushStyle();
    ofSetColor(0,0,255);
	ofDrawBitmapString(s, ofGetWidth()-85,ofGetHeight()-30);
    ofPopStyle();

    
    
    
    if(showDebug)
	{
		drawDebug();
	}

    
    
           
}

//--------------------------------------------------------------

void testApp::spoke(float x,float y, float rout, float rin,float alpha) {
    //not used
    float xindelta=rin*cos(alpha);
    float xoutdelta=rout*cos(alpha);
    float yindelta=rin*sin(alpha);
    float youtdelta=rout*sin(alpha);
    ofSetLineWidth(2);
    
    ofLine(x+xindelta,y-yindelta,x+xoutdelta,y-youtdelta);
}

void testApp::olddraw()
{
	//cout << "draw " << (tabort2++) << endl;
	if (!phototaken) {
		//first draw
	}
	else {
		//cout << maxSound << endl;
		
		ofSetColor(0,255,255);		
		
		//do filtering based on something
		if (!photodrawn) {
            //	filtertype=ofRandom(0,5);
			cout << "filtertype = " << filtertype << endl;
            
		}
		if (filtertype == -1)
		{
            //all filters should go here
        } 
        else 
        { //fallback
            drawImage.draw(0, -61,ofGetWidth(),ofGetHeight());
            photodrawn=true;
        }
        
        if (uploadcountdown>0) {
            uploadcountdown--;
            if (uploadcountdown==0){
                //upload on some draws after picture is taken and filtered, otherwize a white image may be uploaded
                int i=0;
                bool success=false;
                while(!success && i<numberOfUploadThreads){
                    if (!tup[i].isThreadRunning()){
                        tup[i].upload(uploadImage);
                        success=true;
                    }
                    i++;
                }
                if (!success){
                    NSLog(@"%@",@"couldn't upload, all threads running");
                }
             }
        }
        for (int i=0;i<numberOfUploadThreads;i++){
            if (tup[i].isThreadRunning()) {
                cout << "r"; 
            }
            else {
                cout << "n";
            }    
        }
        cout << threadedUpload::count << " ";

    }

    //too be used at some point, maybe
    /*
    if (tup.uploaded) {
        ofSetColor(128,128,128);
        ofRect(6,ofGetHeight()-130,ofGetWidth()-12,24);
        ofSetColor(255, 255, 255);
        ofDrawBitmapString("uploaded", 20, ofGetHeight()-118);

    }
     */
    
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
	if(touch.id == 0 && touch.y > ofGetHeight()- 70)
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
	if(touch.id == 0 && touch.y > ofGetHeight()- 70 && isButtonDown) {
        cout << "touch detected" << endl;
        if (touch.x<100) {
            //stop/start music
            if (chunepaused){
                chune.play();
                chune.setPosition(chuneposition);
            } else {
                chuneposition=chune.getPosition();
                chune.stop();
            }
            chunepaused=!chunepaused;
            
        } else if (touch.x<210) {
            //open camera
            
            if((ofGetElapsedTimeMillis()-imagetime)>taptreshold){ //too avoid double tap on use button
                
                
                //the camera without preview is not working well in new version. here are some alternatives of showing the camera, but no alternative is perfect
                
                
                //what is the difference between 1 and 3? is openCamera not needed at all with showCameraOverlay?
                //and why does the camera not react on lower part of screen?
                
                
                /* xxxxxxxxxxxxxxx
                 drawImage bör göras svart här eller hellre sätt flagga så att svart bild visas. kan man göra en draw här i touchup eller bara i draw? tror man kan här
                 */
                
                
                phototaken=false;
                
                
                if (cameramode==0) {
                    //open camera with preview
                    camera->openCamera();
                } else if (cameramode==1) {
                    //open camera without preview
                    camera->showCameraOverlay();
                } else if (cameramode==2) {
                    //open camera without preview, alt 2. 
                    //camera->showCameraOverlay must be called in setup
                    camera->openCamera();
                } else if (cameramode==3) {
                    //open camera without preview, alt 3. 
                    camera->showCameraOverlay();
                    camera->openCamera();
                } else {
                    //fallback
                    camera->openCamera();
                }
                cout << "camera opened" << endl;
            }
            else {
                cout << "touch too soon, camera not opened. imagetime: " << imagetime << " millis: " << ofGetElapsedTimeMillis() << endl;
            }
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
    
    
// can't get takePicture taking pictures. 
//    camera->takePicture();
//    camera->imageUpdated=true;
//    cout << endl << "takepicture" << endl;
//    if (camera->imageUpdated) {
//        cout << "imageupdated" << endl;
//    }
    
    
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
    cout << "orientation changed " << [UIDevice currentDevice].orientation << endl;
    //seems like we have to use this to be sure of orientation
}



//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs& args){

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


void testApp::drawCassette(int cx,int cy,float scale,float progress,int wi){
    ofPushStyle();
    float cw=cassette.getWidth()*scale;
    float ch=cassette.getHeight()*scale;
    cassette.draw(cx,cy,cw,ch);
    
    //this is the window where the tape shall grow and shrink
    ofSetColor(139,69,19); //brown tape
    //this brown tape could be inte cassette png
    ofRect(cx+113*scale,cy+68*scale,70*scale,38*scale);
    ofSetColor(255,255,255);

    ofRect(cx+113*scale+5*scale+50*scale-50*progress*scale,cy+68*scale,10*scale,38*scale);
    
    wheel[wi].draw(cx+65*scale,cy+68*scale,wheel[wi].getWidth()*scale,wheel[wi].getHeight()*scale);
    wheel[wi].draw(cx+cassette.getWidth()*scale-107*scale,cy+68*scale,wheel[wi].getWidth()*scale,wheel[wi].getHeight()*scale);

    ofPopStyle();

}