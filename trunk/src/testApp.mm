#import <UIKit/UIKit.h>
#include "testApp.h"
#include "filters.h"


//--------------------------------------------------------------
void testApp::setup(){	
	phototaken=false;
	// register touch events
	ofRegisterTouchEvents(this);
	
	// initialize the accelerometer
	ofxAccelerometer.setup();
	
	//iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
	
	cameraPixels = NULL; 
	camera = new ofxiPhoneImagePicker();
	camera->setMaxDimension(480); //otherwise we will have enormous images
	imgPos.x=ofGetWidth()/2;
	imgPos.y=ofGetHeight()/2;
	
	//photo.loadImage("images/instructions.png");
	camera->openCamera();
	//imgPos.x=ofGetWidth()/2;
	//imgPos.y=ofGetHeight()/2;
}


// callback for CGDataProviderCreateWithData
// dirty programming: releasData is already defined in ofziPhoneExtras.mm 
// but i don't know how to get it in this scope, so i made a releasData2 instead
void releaseData2(void *info, const void *data, size_t dataSize) {
	//	NSLog(@"releaseData\n");
	free((void*)data);		// free the 
}


//--------------------------------------------------------------
void testApp::update()
{
	if(camera->imageUpdated){

		
		
		
		// the pixels seem to be flipped, so let's unflip them: 
		if (cameraPixels == NULL){
			// first time, let's get memory based on how big the image is: 
			cameraPixels = new unsigned char [camera->width * camera->height*4];
		}
		// now, lets flip the image vertically:
		for (int i = 0; i < camera->height; i++){
			memcpy(cameraPixels+(camera->height-i-1)*camera->width*4, camera->pixels+i*camera->width*4, camera->width*4);
		}
		
		// finally, set the image from pixels...
		photo.setFromPixels(cameraPixels,camera->width, camera->height, OF_IMAGE_COLOR_ALPHA);

		//ok, här behöver jag en metod (eller funktion) invert med inverteringskoden. 
		
		unsigned char *pixels =  photo.getPixels();

		//filterSelector(2,pixels,camera->width,camera->height,100);

		photo.setFromPixels(pixels,camera->width,camera->height,OF_IMAGE_COLOR_ALPHA);

		imgPos.x=ofGetWidth()/2;
		imgPos.y=ofGetHeight()/2;
		
		camera->imageUpdated=false;

		//////////////////////////////////////////////////////////////////
		//testing some objective c code to upload picture
		//first some slightly modified code from ofxiPhoneExtras.mm to grab image,
		//here used to convert ofimage to UIImage
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
		
		
		
		
		
		//then som code to upload image
		NSData *imageData = UIImageJPEGRepresentation(image, 90);

		
		
		
		
		
		
		
		// setting up the URL to post to
		NSString *urlString = @"http://dvwebb.mah.se/~k3bope/contextphoto/upload.php";
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
		[body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"ipodfile2.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[NSData dataWithData:imageData]];
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		// setting the body of the post to the reqeust
		[request setHTTPBody:body];
		
		// now lets make the connection to the web
		NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
		NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		
		NSLog(returnString);
		
		/////////////////////////////////////////////////////////////////////
		
		cout << "update finished";

		//opencvcode
		tmpImg.allocate(photo.width, photo.height);

		//unsigned char * pixels = photo.getPixels(); //new unsigned char[photo.width * photo.height * 3]
		
		
		IplImage *cvRGBA;
		cvRGBA = cvCreateImage(cvSize(photo.width,photo.height), IPL_DEPTH_8U, 4);
		cvRGBA->imageData = (char*)pixels;
		tmpImg = cvRGBA;
		//tmpImg->setFromPixels(pixels, photo.width, photo.height);
		tmpImg.blur(60);
		//tmpImg.draw(0, 0);
		phototaken=true;
		
		
		
	
	}
	
}

//--------------------------------------------------------------
void testApp::draw()
{
	if (!phototaken) {
		//photo.draw(imgPos.x-photo.width/2,imgPos.y-photo.height/2);
		//cout << "photo.draw ";
	}
	else {
		tmpImg.draw(0, 0);
		//cout << "tmpImg.draw ";
	}
	//cout << "draw finished";
}

//--------------------------------------------------------------
void testApp::exit() {
}


//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs &touch){
	
	if(touch.id == 0){
//		imgPos.x=touch.x;
//		imgPos.y=touch.y;

		camera->openCamera();
		imgPos.x=ofGetWidth()/2;
		imgPos.y=ofGetHeight()/2;
	}
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs &touch){
//	if(touch.id == 1){
//		imgPos.x=touch.x;
//		imgPos.y=touch.y;
//	}		
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs &touch){	
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


