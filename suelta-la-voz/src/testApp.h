#pragma once
#include "ofxOpenCv.h"
#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "senseMaker.h"
#include "filters.h"


//#include "ofxFBOTexture.h"


class threadedUpload : public ofThread {
public:
    unsigned long dis(unsigned long lastcall,string comment){
        //quick fix to time an action
        //put this before and after the code to time:
        //unsigned long last=dis(0,""); dis(last,"comment");
        if (lastcall==0) {
            return ofGetElapsedTimeMicros();
        } else {
            unsigned long now=ofGetElapsedTimeMicros();
            cout << comment << " took " << now-lastcall << " us" << endl;
            return ofGetElapsedTimeMicros();
        }
    }

    
    IplImage* image;
    IplImage* imageTemp;
    static int count; //number of simultaneous uploads
    
    static const int maxSimultaneousUploads=2;

    
    void threadedFunction() {  
        if(lock()) {  
            NSLog(@"Starting upload thread, step 2");
            while (count>=maxSimultaneousUploads){
                //cout << endl << "waiting" << endl;
                ofSleepMillis(2000);        
            }
            count++;
            uploadPicture(imageTemp,true,true);
        
            count--;
            unlock();  
        } else {  
            cout << "cannot save cos I'm locked" << endl;  
        }  
        stopThread();  
    }  
    
    void upload(IplImage* im) {
        NSLog(@"Starting upload thread, step 1");   
        image = cvCreateImage(cvSize(im->width,im->height), IPL_DEPTH_8U, 4);
        imageTemp = cvCreateImage(cvSize(im->width,im->height), IPL_DEPTH_8U, 3);
        unsigned long last=dis(0,"");
        imageTemp=im; //only reference copied, does not take much time
        dis(last,"imagetemp=image");
        startThread(false, false);   // blocking, verbose  
    }  
    
    
    void uploadPicture(IplImage* im,bool savelocal,bool savecloud){
        //before image is saved uploaded it must be converted to UIImage
        //I have tried some alternatives:
        //1 http://programmersgoodies.com/how-to-send-iplimage-from-server-to-ipod-client-uiimage-via-tcp can't get it working
        //2 http://stackoverflow.com/questions/4263365/iphone-converting-iplimage-to-uiimage-and-back-causes-rotation this works!
        //3 http://niw.at/articles/2009/03/14/using-opencv-on-iphone/en this is almost the same as 2
        
        //have to convert image from 3 to 4 channels, otherwise error in CGImageCreate
        cvCvtColor(imageTemp, image, CV_RGB2RGBA);
        
        NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
        CGImageRef imageRef = CGImageCreate(image->width, image->height,
                                            image->depth, image->depth * image->nChannels, image->widthStep,
                                            colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault,
                                            provider, NULL, false, kCGRenderingIntentDefault);
        //with kCGImageAlphaNone|kCGBitmapByteOrderDefault I might not need to do the Alpha conversion
        UIImage *ret = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp]; //possbly this should could be reduced to UIImage *ret = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpace);
        
        if (savelocal){
            UIImageWriteToSavedPhotosAlbum(ret,nil,nil,nil);
        }
 
//everything in uploadPicture before this comment should go into threadedfunction, or better into a function
//ipl->uiimage followed by UIImageWriteToSavedPhotosAlbum(ret,nil,nil,nil). and the following if (svecloud) could also be moved to threadedfunction
        
        if (savecloud){
            //Upload image
            NSData *imageData = UIImageJPEGRepresentation(ret, 1);

            // setting up the URL to post to
            //define several servers if one is down
            //NSString * urlString= @"http://homeweb.mah.se/~k3bope/contextphoto/upload.php";    
            //NSString * urlString= @"http://asynkronix.se/contextphoto/upload2.php";    
            NSString * urlString= @"http://asynkronix.se/contextphoto/upload2.php";    
            
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
            [body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"photoibop.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[NSData dataWithData:imageData]];
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            // setting the body of the post to the reqeust
            [request setHTTPBody:body];
            
            // now lets make the connection to the web
            NSLog(@"Uploading to %@",urlString);
            NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            
            
            if (returnString.length>0) {
                //should search for filename, not relay on upload2.php not changing
                NSLog(@"Uploaded to %@",[returnString substringWithRange:NSMakeRange(289, 44)]);

            }
            else {
                NSLog(@"Upload seems to have failed. Maybe web server timeout.");
            }
            
            
            }

    }
    
    
};


class testApp : public ofxiPhoneApp {
	
public:
	
    
    unsigned long dis(unsigned long lastcall,string comment){
        //quick fix to time an action
        //put this before and after the code to time:
        //unsigned long last=dis(0,""); dis(last,"comment");
        if (lastcall==0) {
            return ofGetElapsedTimeMicros();
        } else {
            unsigned long now=ofGetElapsedTimeMicros();
            cout << comment << " took " << now-lastcall << " us" << endl;
            return ofGetElapsedTimeMicros();
        }
    }

	void setup();
	void update();
	void draw();
	
    void exit();
	
	void touchDown(ofTouchEventArgs &touch);
	void touchMoved(ofTouchEventArgs &touch);
	void touchUp(ofTouchEventArgs &touch);
	void touchDoubleTap(ofTouchEventArgs &touch);
	void touchCancelled(ofTouchEventArgs &touch);
	
	void lostFocus();
	void gotFocus();
	void gotMemoryWarning();
	void deviceOrientationChanged(int newOrientation);
	
	int DetectShake();
    
	senseMaker senseAudio;
    void audioReceived( float * input, int bufferSize, int nChannels );
	ofPoint filteredMax(ofPoint maxacc,ofPoint acc, float alfa);
	ofPoint filteredMin(ofPoint minacc,ofPoint acc, float alfa);
	float vectorabs(ofPoint p);
	void consoleplot(float x,float max,char c);
    
	void drawDebug();
	
    void drawCassette(int cx,int cy,float scale,float progress,int wi);
    

    
	//variables
    unsigned char * cameraPixelsNoAlpha;
	ofxiPhoneImagePicker * camera;
	ofxCvColorImage  drawImage; //this is the image that is drawn in the draw-function

    IplImage *uploadImage; //this is the image that is uploaded in the threaded upload. 
    IplImage *cvImageTemp;

    bool phototaken;

	int filtercountdown; //to allow a few update-draw-cycles before filtering starts
    
    bool manualUpdated;
	
    
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
	   
	bool showDebug;
	
	ofImage buttonDown;
	ofImage buttonUp;
	bool isButtonDown;
    int xDown;
    int yDown;
	
    static const int numberOfUploadThreads=8;
    threadedUpload tup[numberOfUploadThreads];
    
    //musicplayer
    ofSoundPlayer  chune;
    //ofxOpenALSoundPlayer chune; //can play mp3 but not set speed
    bool chunepaused;
    float chuneposition;
    
    
    //cameramode
    int cameramode;

    
    ofImage instaicon;
    
    //cassette animation
    int wi;
    float angle;
    ofImage wheel[6];
    ofImage cassette;
    
    float tabortscale;
    float tabortgrow;
    
    //old variables not used anymore
    //unsigned char * cameraPixelsFlip;	// the camera image needs to be flipped, so we'll use this memory for that. 
	//unsigned char * cameraPixelsRot;	// the camera image sometimes needs to be rotated, so we'll use this memory for that. 
	//unsigned char * cameraPixels;
    //IplImage *cvGray;
	//ofxCvGrayscaleImage ofcvGrayImg;
    //ofxCvContourFinder contourFinder;
	//ofxCvFloatImage ofcvSobelImg;
	//int tabort1;
	//int tabort2;
};

//test committing changes to github from within xcode

/*
 En la fiesta va a bailar 
 Empujaste sin para
 en la fiesta va a bailar
 empujaste para atrás
 estas bailando despistao
 te caiste e medio lao
 en la fiesta va a bailar
 
 
 Suelta la voz 
 Copia Doble te baila la voz
 que la rueda la baila la voz
 Copia Doble te baila la voz
 que te encanta te canta la voz
 esta noche la reina la voz
 Copia Doble te baila la voz 
 que la sueltala, suelta la voz
 
 Tu me empujaste ya vas a parar
 no te preguntes lo que va a pasar
 así me gusta vamos a bailar
 aquí la fiesta esta por explotar
 estas calentando la pista, a bailar
 no te preguntes lo que va a pasar
 estas despistao vente levantar
 es Copia Doble que invita a bailar
 aquí la fiesta esta por explotar calentando la pista vamos a bailar
 
 En la fiesta va a bailar 
 Empujaste sin para
 en la fiesta va a bailar
 empujaste para atrás
 estas bailando despistao
 te caiste e medio lao
 en la fiesta va a bailar
 
 Suelta la voz 
 Copia Doble te baila la voz
 que la rueda la baila la voz
 Copia Doble te baila la voz
 que te encanta te canta la voz
 esta noche la reina la voz
 Copia Doble te baila la voz 
 que la sueltala, suelta la voz
 
 no te preguntes lo que va a pasar
 estas despistao vente levantar
 es Copia Doble que invita a bailar
 aquí la fiesta esta por explotar calentando la pista vamos a bailar
 
 Suelta la voz 
 Copia Doble te baila la voz
 que la rueda la baila la voz
 Copia Doble te baila la voz
 que te encanta te canta la voz
 esta noche la reina la voz
 Copia Doble te baila la voz 
 que la suelta la, suelta la voz 
 
 
 
 */


