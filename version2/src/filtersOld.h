

/*
 *  filtersOld.cpp
 *  contextphoto
 *
 *  Created by mads hobye on 2/4/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */






void testApp::drawball(int mode, int radius){
	//mode 0: setup and draw
	//mode 1: just draw
	//should take avarage color and not just color of centrum pixel...
	int x;
	int y;
	int width=camera->width;
	int height=camera->height;
	//int radius=5;
	int radiusvariation=radius/2;
	int pixelstep=radius*2;
	int stepvariation=pixelstep/2;
	int radiusoffset;
	int xoffset;
	int yoffset;
	int r,g,b;
	int pixel;
	int i;
	
	
	if (mode==0){
		i=0;
		for (x=pixelstep,i=0;x<width;x=x+pixelstep){
			for (y=pixelstep;y<height;y=y+pixelstep){
				xoffset=ofRandom(-stepvariation,stepvariation);
				yoffset=ofRandom(-stepvariation,stepvariation);
				radiusoffset=int(ofRandom(-radiusvariation,radiusvariation));
				pixel=(y+yoffset)*width+x+xoffset;
				if (pixel<0) {
					pixel=0;
				}
				if (pixel>=width*height){
					pixel=width*height-1;
				}
				
				pixelArray[i]=pixel;
				radiusoffsetArray[i]=radiusoffset;
				
				//			r=cameraPixels[pixel*4];
				//			g=cameraPixels[pixel*4+1];
				//			b=cameraPixels[pixel*4+2];
				//			ofSetColor(r,g,b);
				//			ofCircle(x+xoffset,y+yoffset,radius+radiusoffset);
				i++;
			}
		}
		imax=i;
	}
	//nu måste man ha imax pixelArray och radiusoffsetArray som globala
	if (mode>=0){
		for (i=0;i<imax;i++){
			pixel=pixelArray[i];
			radiusoffset=radiusoffsetArray[i];
			x=pixel%width;
			y=pixel/width;
			r=cameraPixels[pixel*4];
			g=cameraPixels[pixel*4+1];
			b=cameraPixels[pixel*4+2];
			ofSetColor(r,g,b);
			ofCircle(x,y,radius+radiusoffset);
			
		}
	}
	
	//cout <<"i "<<i<<" width*..."<<(width*height/pixelstep/pixelstep)<<endl;
}

void testApp::drawrect(int mode,int radius){
	//mode 0: setup and draw
	//mode 1: just draw
	int x;file://localhost/Users/k3bope/Dropbox/Dropuments/code/openframework/apps/contextphoto/trunk/src/testApp.h
	int y;
	int width=camera->width;
	int height=camera->height;
	//	int radius=20; //actualy width/2 but wtf
	int radiusvariation=radius/2;
	int pixelstep=radius*2;
	int stepvariation=pixelstep/2;
	int radiusoffset; 
	int xoffset;
	int yoffset;
	int r,g,b;
	int pixel;
	int i;
	
	
	if (mode==0){
		i=0;
		for (x=pixelstep,i=0;x<width;x=x+pixelstep){
			for (y=pixelstep;y<height;y=y+pixelstep){
				xoffset=ofRandom(-stepvariation,stepvariation);
				yoffset=ofRandom(-stepvariation,stepvariation);
				radiusoffset=int(ofRandom(-radiusvariation,radiusvariation));
				pixel=(y+yoffset)*width+x+xoffset;
				if (pixel<0) {
					pixel=0;
				}
				if (pixel>=width*height){
					pixel=width*height-1;
				}
				
				pixelArray[i]=pixel;
				radiusoffsetArray[i]=radiusoffset;
				
				//			r=cameraPixels[pixel*4];
				//			g=cameraPixels[pixel*4+1];
				//			b=cameraPixels[pixel*4+2];
				//			ofSetColor(r,g,b);
				//			ofCircle(x+xoffset,y+yoffset,radius+radiusoffset);
				i++;
			}
		}
		imax=i;
	}
	//nu måste man ha imax pixelArray och radiusoffsetArray som globala
	if (mode>=0){
		for (i=0;i<imax;i++){
			pixel=pixelArray[i];
			radiusoffset=radiusoffsetArray[i];
			x=pixel%width;
			y=pixel/width;
			r=cameraPixels[pixel*4];
			g=cameraPixels[pixel*4+1];
			b=cameraPixels[pixel*4+2];
			ofSetColor(r,g,b);
			ofRect(x-radius-radiusoffset,y-radius-radiusoffset,2*(radius+radiusoffset),2*(radius+radiusoffset));
			//ofCircle(x,y,radius+radiusoffset);
			
		}
	}
	
	//cout <<"i "<<i<<" width*..."<<(width*height/pixelstep/pixelstep)<<endl;
}


void testApp::drawtriang(int mode,int radius){
	//mode 0: setup and draw
	//mode 1: just draw
	int x;file://localhost/Users/k3bope/Dropbox/Dropuments/code/openframework/apps/contextphoto/trunk/src/testApp.h
	int y;
	int width=camera->width;
	int height=camera->height;
	//	int radius=10; 
	//	int radiusvariation=5;
	//	int stepvariation=5;
	//	int pixelstep=15;
	int radiusvariation=radius/2;
	int pixelstep=radius*2;
	int stepvariation=pixelstep/2;
	
	
	int radiusoffset; 
	int xoffset;
	int yoffset;
	int r,g,b;
	int pixel;
	int i;
	int rotation;
	
	
	if (mode==0){
		i=0;
		for (x=pixelstep,i=0;x<width;x=x+pixelstep){
			for (y=pixelstep;y<height;y=y+pixelstep){
				xoffset=ofRandom(-stepvariation,stepvariation);
				yoffset=ofRandom(-stepvariation,stepvariation);
				radiusoffset=int(ofRandom(-radiusvariation,radiusvariation));
				pixel=(y+yoffset)*width+x+xoffset;
				if (pixel<0) {
					pixel=0;
				}
				if (pixel>=width*height){
					pixel=width*height-1;
				}
				rotation=ofRandom(0,360);
				pixelArray[i]=pixel;
				radiusoffsetArray[i]=radiusoffset;
				rotationArray[i]=rotation;
				//			r=cameraPixels[pixel*4];
				//			g=cameraPixels[pixel*4+1];
				//			b=cameraPixels[pixel*4+2];
				//			ofSetColor(r,g,b);
				//			ofCircle(x+xoffset,y+yoffset,radius+radiusoffset);
				i++;
			}
		}
		imax=i;
	}
	//nu måste man ha imax pixelArray och radiusoffsetArray som globala
	if (mode>=0){
		for (i=0;i<imax;i++){
			pixel=pixelArray[i];
			radiusoffset=radiusoffsetArray[i];
			rotation=rotationArray[i];
			x=pixel%width;
			y=pixel/width;
			r=cameraPixels[pixel*4];
			g=cameraPixels[pixel*4+1];
			b=cameraPixels[pixel*4+2];
			ofSetColor(r,g,b);
			myTriangle(x,y,rotation,radius+radiusoffset);
			//ofRect(x-radius-radiusoffset,y-radius-radiusoffset,2*(radius+radiusoffset),2*(radius+radiusoffset));
			//ofCircle(x,y,radius+radiusoffset);
			
		}
	}
	
	//cout <<"i "<<i<<" width*..."<<(width*height/pixelstep/pixelstep)<<endl;
}


void testApp::myTriangle(int x,int y,int rotation,int r){
	//rotation in degrees
	int x1=x+r*cos((30.0f+rotation)*PI/180.0f);
	int y1=y+r*sin((30.0f+rotation)*PI/180.0f);
	int x2=x+r*cos((-90.0f+rotation)*PI/180.0f);
	int y2=y+r*sin((-90.0f+rotation)*PI/180.0f);
	int x3=x+r*cos((150.0f+rotation)*PI/180.0f);
	int y3=y+r*sin((150.0f+rotation)*PI/180.0f);
	ofTriangle(x1,y1,x2,y2,x3,y3);
}
