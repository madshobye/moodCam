//
//  threadedUpload.h
//  ImagePickerExample
//
//  Created by Bo Peterson on 2011-11-25.
//  Copyright (c) 2011 Malmö högskola. All rights reserved.
//
#pragma once
#include "ofxOpenCv.h"
#include "ofMain.h"


class threadedUpload2 : public ofThread {
public:
    IplImage* image;
    IplImage* imageTemp;
    
    void threadedFunction() {  
        if(lock()) {  
            NSLog(@"Starting upload thread, step 2");
            uploadPicture(imageTemp,true,true);
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
        imageTemp=im;
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
            
            NSLog(@"%@",returnString);
            NSLog(@"uploaded");
        }
        
    }
    
    
};
