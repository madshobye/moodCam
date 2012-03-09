#import <UIKit/UIKit.h>
#include "testApp.h"

int threadedUpload::count=0;

const char * tickstring = new char[100];
int tick(int last, const char * s) {
    int now=ofGetElapsedTimeMillis();
    if (now>(last+1000)) {
        cout << s << endl;
        return now;
    } else {
        return last;
    }
}

//--------------------------------------------------------------
void testApp::setup(){	
    
    
    
    ofBackground(0,0,0);
    filtercountdown=0;

    lasttick=0;
    
    //size and position of icons and buttons
    cassetteButton.set(1*107,ofGetHeight()-67,107,67);
    cameraButton.set(0*107,ofGetHeight()-67,107,67);
    settingsButton.set(2*107,ofGetHeight()-67,107,67);
    fastforwardButton.set(2*107,ofGetHeight()-67,107,67);
    reverseButton.set(0*107,ofGetHeight()-67,107,67);
    
    
    
    //images for cassette animation
    wheel[0].loadImage("images/hjul00-14x14.png");
    wheel[1].loadImage("images/hjul10-14x14.png");
    wheel[2].loadImage("images/hjul20-14x14.png");
    wheel[3].loadImage("images/hjul30-14x14.png");
    wheel[4].loadImage("images/hjul40-14x14.png");
    wheel[5].loadImage("images/hjul50-14x14.png");
    cassette.loadImage("images/cassette-noalpha-107x69.png");
    wi=0;
   
    
    instaicon.loadImage("images/instamatic-noalpha-107x69.png");
    settingsicon.loadImage("images/chaplin107x69.png");

    
    
    
    propertySize = sizeof(CFStringRef);
    
    OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
    UInt32 category = kAudioSessionCategory_PlayAndRecord; 
    result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);       
    AudioSessionSetActive(YES);
    speaker=false;
    headphonesConnected=false;
    dockConnected=false;
    receiver=false;
    receiverOld=false;
    audioroute = new char[50];

//    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
//    if((route == NULL) || (CFStringGetLength(route) == 0)){
//        // Silent Mode
//        routeStr=@"silent";
//    } else {
//        routeStr = (NSString*)route;
//    }
//     
//    audioroute=[routeStr UTF8String];
//    //har inte testat både lineout och hörlurar. vad blir det då?
//    if (strcmp(audioroute,"LineOut")==0) {
//        dockConnected=true;
//    } else if (strcmp(audioroute,"HeadsetInOut")==0) {
//        headphonesConnected=true;
//    } else if (strcmp(audioroute,"HeadphonesAndMicrophone")==0) {
//        headphonesConnected=true;
//    } else if (strcmp(audioroute,"ReceiverAndMicrophone")==0) {
//        receiver=true;
//    }
//    if (receiver) {
//        //redirect sound from receiver to speaker
//        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
//        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
//        receiver=false;
//    }
    
    chune.loadSound("sounds/suelta-la-voz.caf");
	chune.setVolume(1.0f);
	chune.setMultiPlay(false);
    chuneReverse.loadSound("sounds/suelta-la-voz_reverse.caf");
	chuneReverse.setVolume(1.0f);
	chuneReverse.setMultiPlay(false);

    chunepaused=true;
    chuneReversepaused=true;
    chuneWasPlaying=false;
    chuneposition=0;
    
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
    
    //check headphones or lineout
    //check if headphones or lineout connected
    //    HeadsetInOut
    //    ReceiverAndMicrophone
    //    SpeakerAndMicrophone
    //    LineOut
    //    HeadphonesAndMicrophone
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
    if((route == NULL) || (CFStringGetLength(route) == 0)){
        // Silent Mode
        routeStr=@"silent";
    } else {
        routeStr = (NSString*)route;
    }
    
    audioroute=[routeStr UTF8String];
    //har inte testat både lineout och hörlurar. vad blir det då?
    if (strcmp(audioroute,"LineOut")==0) {
        dockConnected=true;
    } else if (strcmp(audioroute,"HeadsetInOut")==0) {
        headphonesConnected=true;
    } else if (strcmp(audioroute,"HeadphonesAndMicrophone")==0) {
        headphonesConnected=true;
    } else if (strcmp(audioroute,"ReceiverAndMicrophone")==0) {
        receiver=true;
    }
    if (receiver) {
        //redirect sound from receiver to speaker
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
        receiver=false;
        cout << "redirecting to speaker" << endl;
    }
    
    if ((!dockConnected && dockConnectedOld) || (!headphonesConnected && headphonesConnectedOld)) {
        //stop chune
        if (chune.getIsPlaying()) {
            chuneposition=chune.getPosition();
            cout << "chune was stopped by removed headphones/lineout" << endl;
            chune.stop();
            chunepaused=true;
        } else if (chuneReverse.getIsPlaying()) {
            cout << "chuneReverse was stopped by removed headphones/lineout" << endl;
            chuneposition=1.0-chuneReverse.getPosition();
            chuneReverse.stop();
            chuneReversepaused=true;
        }
        
        
    }
    dockConnectedOld=dockConnected;
    headphonesConnectedOld=headphonesConnected;

    
    if(camera->imageUpdated){
        if (filtercountdown>0) {
            //this is to prevent the preview screen from sticking until filtered image is drawn
            //which sometimes happens if you don't do a few update and draw after camera->imageUpdate
            filtercountdown--;
        } else 
        {
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

            
            //cout << "orientation A: " << orientationA << ", orientation B: " << orientationB << ", orientation C " << orientationC << endl;
            
            
            
            
            
            
            if (cameraPixelsNoAlpha == NULL){
                cameraPixelsNoAlpha = new unsigned char [camera->width * camera->height*3];
            }
            if (pixelsTemp == NULL){
                pixelsTemp = new unsigned char [camera->width * camera->height*3];
            }
                    
                       
            cout << "width: " << camera->width << endl;
            cout << "height: " << camera->height << endl;
            cout << "window width: " << ofGetWidth() << endl;
            cout << "window height: " << ofGetHeight() << endl;
            drawImage.clear();
            drawImage.allocate(camera->width, camera->height);
            
            unsigned long now=dis(0,"");        
            //delete alphachannel
            for (int i=0,j=0;i<camera->width*camera->height*4;i+=4){
                memcpy(cameraPixelsNoAlpha+j,camera->pixels+i,3);
                j+=3;
            }
            dis(now,"removal of alphachannel");
            
            //time for filtering
            //to start with, for the filters to work with, we have the image drawImage of type ofxCvColorImage
            //and when we are ready we should have the filtered image back in drawImage (drawn) but
            //we also need the filtered image in uploadImage (uploaded)
            //
            //HOWTO CALL FILTER FUNCTIONS:
            //There are two different ways. Calling with
            //1. cameraPixelsNoAlpha or 
            //2. uploadImage
            //No 1 is called like this:
            //
            //     filterGlitch(cameraPixelsNoAlpha,camera->width,camera->height,senses);            
            //     drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            //     uploadImage=drawImage.getCvImage();
            //
            //No 2 is called like this:
            //
            //     drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
            //     uploadImage=drawImage.getCvImage();
            //     filterCurves_2(uploadImage, drawImage.getWidth(), drawImage.getHeight(),senses); //amount should be affected by senses
            //
            //Note that the filter-function will alter uploadImage, and that this will also alter drawImage as intended in the second
            //alternative. 
            //
            //Note also that there are more alternatives:
            //applying more than one filter, possibly a combination of 1 and 2.
            //This could be done like this:
//            alt 1 filter followed by alt 2 filter:
//            filterGlitch(cameraPixelsNoAlpha,camera->width,camera->height,senses);            
//            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
//            uploadImage=drawImage.getCvImage();
//            filterSmooth(uploadImage, drawImage.getWidth(), drawImage.getHeight(),20);
//
//            alt 2 filter followed by alt 1 filter:
//            drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
//            uploadImage=drawImage.getCvImage();
//            filterSmooth(uploadImage, drawImage.getWidth(), drawImage.getHeight(),20);
//            pixelsTemp=drawImage.getPixels();
//            filterGlitch(pixelsTemp,camera->width,camera->height,senses);            
//            drawImage.setFromPixels(pixelsTemp,camera->width,camera->height);
//            uploadImage=drawImage.getCvImage();
            
            
            
            //
            //some old notes on this:
            /*            uploadImage=cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 3);
             filterFrameit(drawImage.getPixels() , drawImage.getWidth(), drawImage.getHeight(),-1);
             uploadImage=drawImage.getCvImage(); //very very strange. if portrait mode, original and not filtered image copied to uploadImage
             //but correct filtered image drawn by drawImage.draw. weird. maybe because of documented bug in getPixels ofxCVimage.cpp
             //try getCvROIImage...
             */          
            //yes, this was the way to do it. 
            //but must find a way to do it if appying two filters, one with pixels, one with iplimage...
            //no problem if working with pixels before iplimage, but maybe problem if working with
            //pixels after iplimage.  how to get pixels from iplimage??? answer: img->imageData

            
            now=dis(0,"");
            if (filtertype==0) {
                //no filter
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
            } else if (filtertype==1) {
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
                filterCurves_2(uploadImage, drawImage.getWidth(), drawImage.getHeight(),senses); //amount should be affected by senses
            } else if (filtertype==2) {
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
                filterCurves_hsv(uploadImage, drawImage.getWidth(), drawImage.getHeight(),senses); //amount should be affected by senses
            } else if (filtertype==3) {
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
                filterVignette_2(uploadImage, drawImage.getWidth(), drawImage.getHeight(),-1);
            } else if (filtertype==4) {
                for(int i =0; i < 10;i++)
				{
					ant(cameraPixelsNoAlpha,ofRandom(0,drawImage.getWidth()), ofRandom(0,drawImage.getHeight()),ofRandom(0,2*PI),drawImage.getWidth(), drawImage.getHeight(), 8,senses);
				}
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
            } else if (filtertype==5) {
                filterFrameit(cameraPixelsNoAlpha,camera->width,camera->height,-1);            
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();        
            } else if (filtertype==6) {
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
                filterCurves_crazy(uploadImage, drawImage.getWidth(), drawImage.getHeight(),senses); //amount should be affected by senses
            } else if (filtertype==7) {           
                filterGlitch(cameraPixelsNoAlpha,camera->width,camera->height,senses);            
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
            } else if (filtertype==8) {
                filterGeneral(cameraPixelsNoAlpha,camera->width,camera->height,-1);            
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
            } else if (filtertype==9) {
                filterInvert(cameraPixelsNoAlpha,camera->width,camera->height,-1);            
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
            } else if (filtertype==10) {
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
                filterSmooth(uploadImage, drawImage.getWidth(), drawImage.getHeight(),20);
            } else if (filtertype==11) {
                //test, applying more than one filter, alt 1 followed by 2
                //alt 1 filter
                filterGlitch(cameraPixelsNoAlpha,camera->width,camera->height,senses);            
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();

                //alt 2 filter
                filterSmooth(uploadImage, drawImage.getWidth(), drawImage.getHeight(),20);

                
                //should be as straight forward as this
            } else if (filtertype==12) {
                //test applying more than one filter, alt 2 followed by 1
                //alt 2 filter
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();
                filterSmooth(uploadImage, drawImage.getWidth(), drawImage.getHeight(),20);
                
                //alt 1 filter
                int temptime=dis(0,"");
                pixelsTemp=drawImage.getPixels(); //takes 4ms
                dis(temptime,"pixelsTemp=drawImage.getPixels()");
                filterGlitch(pixelsTemp,camera->width,camera->height,senses);            
                drawImage.setFromPixels(pixelsTemp,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();

                //now it actually seems to work... don't really lika all conversion steps involved
                //but let's do like this for now
                //
                //NOTE crashes sometimes. Don't know exactly why but I guess it has to do 
                //with filtertype 12...but I can't reproduce it and really don't know what is happening
                
                
            } else {
                drawImage.setFromPixels(cameraPixelsNoAlpha,camera->width,camera->height);
                uploadImage=drawImage.getCvImage();            
            }            
            char* s = new char[50];
            sprintf(s,"filtering time, filter %i: ",filtertype);
            dis(now,s);

            camera->imageUpdated=false;
            phototaken=true;
            
            
            //to temporarily prevent upload:
            //set numberOfUploadThreads=0 in testApp.h
            //or simply say while(!success && i<0){  //numberOfUploadThreads){
            //instead of
            //while(!success && i<numberOfUploadThreads){

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
	}
    //if (camera->imageUpdated) ends here
    
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
	
	

    
    
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
    
    if((route == NULL) || (CFStringGetLength(route) == 0)){
        // Silent Mode
        routeStr=@"silent";
    } else {
        routeStr = (NSString*)route;
    }
    
    tickstring = [routeStr UTF8String];

    lasttick=tick(lasttick,tickstring);
	
    
}

void testApp::draw() {
//too many scale calculations done in draw. Should be done once in setup
    if (!phototaken) {
        ofSetColor(255,100,0);//orange for debugging purposes
        ofRect(0, 0, ofGetWidth(), ofGetHeight());
        if (camera->imageUpdated){      
            //here we should say something like please wait, filtering in progress.......
            ofSetColor(100,255,0);
            char* s = new char[30];
            sprintf(s, "%s", "filtering...");
            ofDrawBitmapString(s, 20, ofGetHeight()-200);
        }
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
    
        //sprintf(tickstring,"drawHeight: %4.1f, drawWidth: %4.1f, ofGetwidth: %i, ofGetHeight: %i, imagewidth: %d, imageheight: %d",drawHeight,drawWidth,ofGetWidth(),ofGetHeight(),drawImage.width,drawImage.height); 


    }

    if (!chunepaused && !chune.getIsPlaying()) {
        cout << "end of chune reached. " << chune.getPosition() << endl;
        chunepaused=true;
        chuneWasPlaying=true; //to prevent chune from restarting if touchMoved in fastforward area after end is reached
        chuneposition=0;
    }

    
    
    //the cassette image is 299x192 px and scaled down to 105x67px
    //this scaling could be done once in photoshop instead to save some calculations
    //the instamatic icon i 161x96 px scaled down to 113x67 px. could also be 'shopped. 
    //finally, the square to the right is maybe 320-105-113=102 px if instamaic next to cassette,
    //but seems like instamatic drawn in center instead. doesn't really matter. 
    // (320/3=106,7)
    
    
    int cx=cassetteButton.x;
    int cy=cassetteButton.y-3;
    
    float progress;
    if (chune.getIsPlaying()) {
        progress=chune.getPosition();
        wi++;
        if (wi>5){ 
            wi=0;
        }
        if (chune.getSpeed()>1.5) {
            wi++;
            if (wi>5){ 
                wi=0;
            }
        }
    } else if (chuneReverse.getIsPlaying()) {
        progress=1-chuneReverse.getPosition();
        wi--;
        if (wi<0){ 
            wi=5;
        }
        if (chuneReverse.getSpeed()>1.5) {
            wi--;
            if (wi<0){ 
                wi=5;
            }
        }
    } else {
        progress=chuneposition;
    }

    ofSetColor(200,200,200);
    drawCassette(cx,cy,progress,wi);

    //draw instamatic icon
    int ix=cameraButton.x;
    int iy=cameraButton.y-3;
    
    instaicon.draw(ix,iy);
    
     
    
    //draw rectangle (to be substituted with something useful
    int sx=settingsButton.x;
    int sy=settingsButton.y-3;
    
    settingsicon.draw(sx,sy);
    

    
    
    
    if(showDebug)
	{
		drawDebug();
	}

    
    
           
}

//--------------------------------------------------------------




void testApp::drawDebug()
{
    
	ofSetColor(50, 50, 50,90);
	
	
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
    
    ofPushStyle();
    s = new char[30];
    sprintf(s, "%.3f %.2f", chune.getPosition(),chuneposition); 
    ofSetColor(0,0,255);
	ofDrawBitmapString(s, ofGetWidth()-85,ofGetHeight()-180);
    sprintf(s, "%.3f", 1-chuneReverse.getPosition()); 
	ofDrawBitmapString(s, ofGetWidth()-85,ofGetHeight()-170);    
    ofPopStyle();

	
}

//--------------------------------------------------------------
void testApp::exit() {
}



/*
touchdown är straightforward. kolla egenetligen bara var man klickar, och om man 
klickar i kassett så kolla även om den spelar eller inte
 
touchup är hyfsat straightforward. gör det mesta om man gör touchup i samma som touchdown och inte varit utanför
men: måste även göra lite bookkeeping om man varit utanför. Vad?
man kan alltid sätta speed till 1
ok, där där jag sätter speed till 1 skulle jag också behöva stoppa spelaren om den är i fastforward
 
 
 
 
 
 
 
 */

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs &touch){
	touchDownPoint.set(touch.x,touch.y);
    if (touch.id==0) {
        if (cassetteButton.inside(touchDownPoint)) {
            isButtonDown=true;
            hasBeenOut=false;
            touchDownButton=cassetteb;
            //check if tune was playing or not at touchDown
            chuneWasPlaying=!chunepaused;
        } else if (cameraButton.inside(touchDownPoint)) {
            isButtonDown=true;
            hasBeenOut=false;
            touchDownButton=camerab;
        } else if (settingsButton.inside(touchDownPoint)) {
            isButtonDown=true;
            hasBeenOut=false;
            touchDownButton=settingsb;
        } else {
            isButtonDown=false;
            hasBeenOut=false;
            touchDownButton=unknownb;
        }
    }
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs &touch){
    touchMovedPoint.set(touch.x,touch.y);
    if (touch.id==0) {
        //first some general stuff for all buttons, checking how we have moved
        if ((touchDownButton==cassetteb && !cassetteButton.inside(touchMovedPoint)) ||
            (touchDownButton==camerab   && !cameraButton.inside(touchMovedPoint)) ||
            (touchDownButton==settingsb && !settingsButton.inside(touchMovedPoint))) {
            hasBeenOut=true;
        }

        if (fastforwardButton.inside(touchMovedPoint)) {
            movedIntoButton=fastforwardsb;
        } else if (reverseButton.inside(touchMovedPoint)) {
            movedIntoButton=reversesb;
        } else {
            movedIntoButton=unknownsb;
        }
        
        //then some specific actions depending on the moves.
        

        if (touchDownButton==cassetteb) {
            if (movedIntoButton==fastforwardsb) {
                float newSpeed=(touchMovedPoint.x-fastforwardButton.x)/10+1;
                chune.setSpeed(newSpeed);
                if (chunepaused && !chuneWasPlaying){
                    cout << "chune started by a move" << endl;
                    chune.play();
                    chune.setPosition(chuneposition);
                    chunepaused=false;
                }
            } else if (movedIntoButton==reversesb) {
                //set speed negative does not work, will have to play reverse version instead :(

                //must stop chune if it is playing and chuneReverse is started
                if (chuneWasPlaying && !chunepaused) {
                    chuneposition=chune.getPosition();
                    chune.stop();
                    chunepaused=true;
                }
                
                float newSpeed=(reverseButton.x+reverseButton.width-touchMovedPoint.x)/10+1; 
                chuneReverse.setSpeed(newSpeed);
                cout << newSpeed << endl;
                //xxx: the following two if statements could be one, without chuneWasPlaying 
                if (chuneReversepaused && chuneWasPlaying){
                    cout << "chuneReverse started by a move, chune was already playing (chune temporarily stopped)" << endl;
                    chuneReverse.play();
                    chuneReverse.setPosition(1-chuneposition);
                    chuneReversepaused=false;
                }

                if (chuneReversepaused && !chuneWasPlaying){
                    cout << "chuneReverse started by a move" << endl;
                    chuneReverse.play();
                    chuneReverse.setPosition(1.0-chuneposition);
                    chuneReversepaused=false;
                }
                
                
                
            } else {
                if (!chunepaused && !chuneWasPlaying) {
                    //chune was started by a move and must be stopped when  
                    //out of fastforward but also on touch up!
                    cout << "chune was stopped by a move" << endl;
                    chuneposition=chune.getPosition();
                    chune.stop();
                    chunepaused=true;
                }
                if (!chuneReversepaused && !chuneWasPlaying) {
                    cout << "chuneReverse was stopped by a move" << endl;
                    if (chuneReverse.getIsPlaying()) {
                        chuneposition=1.0-chuneReverse.getPosition();
                    } else {
                        //chuneReverse has reached end (ie beginning!)
                        chuneposition=0;
                    }
                    chuneReverse.stop();
                    chuneReversepaused=true;
                }
                if (!chuneReversepaused && chuneWasPlaying) {
                    cout << "chuneReverse was stopped by a move, chune resumed" << endl;
                    if (chuneReverse.getIsPlaying()) {
                        chuneposition=1.0-chuneReverse.getPosition();
                    } else {
                        //chuneReverse has reached end (ie beginning!)
                        chuneposition=0;
                    }
                    chuneReverse.stop();
                    chuneReversepaused=true;
                    //for some weird reason, chune.setPosition does not seem to work if it is done immediately 
                    //after chunereverse is stopped, so I add a short pause
                    ofSleepMillis(10); 
                    chune.play();
                    chune.setPosition(chuneposition);                    
                    chunepaused=false;        
                }
                
                chune.setSpeed(1.0);
                chuneReverse.setSpeed(1.0);
            }
        }
        
        //have to start the tune here if it wasn't playing. and stopped both here and in touchup I guess
        
        
    }
    
    
//    if (touch.id==0) {
//        
//        if (touch.x>100 && !chunepaused){
//            //cout << "touch Moved: " << touch.x << endl;
//            chune.setSpeed((touch.x-100)/10+1);
//            cout << chune.getSpeed() << endl;
//        }
//        else {
//            chune.setSpeed(1);
//        }
//    }
    
    
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs &touch){
    touchUpPoint.set(touch.x,touch.y);
    if (touch.id==0) {
        if (cassetteButton.inside(touchUpPoint)) {
            touchUpButton=cassetteb;
        } else if (cameraButton.inside(touchUpPoint)) {
            touchUpButton=camerab;
        } else if (settingsButton.inside(touchUpPoint)) {
            touchUpButton=settingsb;
        } else {
            touchUpButton=unknownb;
        }
        
        
        //ok, we should look for basically three alternatives:
        //1: touchdown and up in same button without having been out
        //2: touchdown and up in same button, having been out
        //3: touchdown in one button, touchup in another button

        if (touchUpButton==touchDownButton && isButtonDown && !hasBeenOut){
            //1: touchdown and up in same button without having been out
            if (touchUpButton==cassetteb) {
                cout << "touch down+up in cassette area detected. toggle play." << endl;
                //toggle play
                if (chunepaused){
                    chune.play();
                    chune.setPosition(chuneposition);
               } else {
                    chuneposition=chune.getPosition();
                    chune.stop();
                }
                chunepaused=!chunepaused;
            } else if (touchUpButton==camerab) {
                //open camera
                if((ofGetElapsedTimeMillis()-imagetime)>taptreshold){ //too avoid double tap on use button                    
                    //the camera without preview is not working well in new version. here are some alternatives of showing the camera, but no alternative is perfect
                    
                    //what is the difference between 1 and 3? is openCamera not needed at all with showCameraOverlay?
                    //and why does the camera not react on lower part of screen
                    
                    phototaken=false;
                    filtercountdown=3;
                    
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

            } else if (touchUpButton==settingsb) {
                //do nothing yet
            }
        }
 
        if (touchUpButton==touchDownButton && isButtonDown && hasBeenOut){
            //2: touchdown and up in same button, having been out
            //nothing has to be done here at the moment
        }
        if (touchUpButton!=touchDownButton && isButtonDown){
            //3: touchdown in one button, touchup in another button
            if (touchDownButton==cassetteb && !chunepaused && !chuneWasPlaying) {
                //chune was started by a move and must be stopped when  
                //out of fastforward but also on touch up!
                chuneposition=chune.getPosition();
                cout << "chune was stopped by touchMove followed by touchUp" << endl;
                chune.stop();
                chunepaused=true;
            }
            if (touchDownButton==cassetteb && !chuneReversepaused && !chuneWasPlaying) {
                if (chuneReverse.getIsPlaying()) {
                    chuneposition=1.0-chuneReverse.getPosition();
                } else {
                    //chuneReverse has reached end (ie beginning!)
                    chuneposition=0;
                }
                cout << "chuneReverse was stopped by touchMove followed by touchUp" << endl;
                chuneReverse.stop();
                chuneReversepaused=true;
            }
            if (touchDownButton==cassetteb && !chuneReversepaused && chuneWasPlaying) {
                cout << "chuneReverse was stopped touchMove followed by touchUp, chune resumed" << endl;
                if (chuneReverse.getIsPlaying()) {
                    chuneposition=1.0-chuneReverse.getPosition();
                } else {
                    //chuneReverse has reached end (ie beginning!)
                    chuneposition=0;
                }
                chuneReverse.stop();
                chuneReversepaused=true;
                //for some weird reason, chune.setPosition does not seem to work if it is done immediately 
                //after chunereverse is stopped, so I add a short pause
                ofSleepMillis(10); 
                chune.play();
                chune.setPosition(chuneposition);                    
                chunepaused=false;        
            }
        }
        
 //xxx this should work now, but I haven't tested what happens when end of chune is reached during reverse       
        isButtonDown=false;    
        chune.setSpeed(1.0); //speed should always be set to 1.0 when no button is down
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
}



//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs &touch){
    
    cout << "double tap, touch.id: " << touch.id << endl;    
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


void testApp::drawCassette(int cx,int cy,float progress,int wi){
//delete scale soon
    ofPushStyle();
    cassette.draw(cx,cy);
 
    //this is the window where the tape shall grow and shrink
    ofSetColor(139,69,19); //brown tape
    //this brown tape could be inte cassette png
    
    ofRect(cx+41,cy+24,24,14);
    ofSetColor(255,255,255);
    ofRect(cx+41+2+16*(1-progress),cy+24,4,14);

    wheel[wi].draw(cx+23,cy+24); 
    wheel[wi].draw(cx+68,cy+24);
    
    ofPopStyle();
    
}





