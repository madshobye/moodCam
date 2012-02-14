/*
 *  filters.cpp
 *  iPhoneImagePickerExample
 *
 *  Created by Bo Peterson on 2010-10-04.
 *  Copyright 2010 Malmö högskola. All rights reserved.
 *
 */

#include "filters.h"



void filterSelector(int filternumber, unsigned char * pixels,int width, int height, int amount){
	//don't know switch syntax in c++, using if instead
	cout<< "selecting filter number " << filternumber << endl;
	if (filternumber==0){
		filterGeneral(pixels, width, height, amount);
	} 
	else if (filternumber==1){
		filterInvert(pixels, width, height, amount);
	} 
	else if (filternumber==2){
		filterInvertRB(pixels, width, height, amount);
	} 
}
	
//--------------------------------------------------------------
void filterGeneral(unsigned char * pixels,int width, int height, int amount){
	//filter #0
	for(int i=0 ; i <width*height*4;  i=i+2-((i%4)!=2))
		//i=i+2-((i%4)!=2) ??? geekiest way i could think of to count 0 1 2 4 5 6 8 9 10... (skipping every forth element containing alpha channel)
		//ok, i+=2-((i%4)!=2) might be even geekier...
	{
		//inverting 0 1 2 3 5 6 7 9 10 11 13 14 15 17 18 19 21 22 23 25 26 27 29 and then normal 
		//invert of picture is also quite nice
		if ((i % 4) == 0) //R
		{
			pixels[i] = 0; 255-pixels[i];
		}
		if ((i % 4) == 1) //G
		{
			pixels[i] = 55-pixels[i];
		}
		if ((i % 4) == 2) //B
		{
			pixels[i] = 200-pixels[i];
		}
	}
}

//--------------------------------------------------------------
void filterInvert(unsigned char * pixels,int width, int height, int amount){
	//filter #1
	//amount is an integer between 0 and 100 but is not used in this filter
	cout << "filterInvert applied, " <<  amount << "%" << endl;
	for(int i=0 ; i <width*height*4;  i+=4) 
	{
		//R
		pixels[i] = 255-pixels[i];
		//G
		pixels[i+1] = 255-pixels[i+1];
		//B
		pixels[i+2] = 255-pixels[i+2];
	}
}


void filterInvertRB(unsigned char * pixels,int width, int height, int amount){
	//filer #2
	std::cout << "filterInvertRB applied" << endl;
	for(int i=0 ; i <width*height*4;  i+=4) 
	{
		//R
		pixels[i] = 255-pixels[i];
		//B
		pixels[i+2] = 255-pixels[i+2];
	}
}

void filterCurves(unsigned char * pixels,int width, int height, int amount)
	{
		
		MSA::Interpolator2D				spline2D[3];
		MSA::InterpolationType			interpolationType	= MSA::kInterpolationCubic;
		float curves[3][255];

		
		spline2D[0].push_back(MSA::Vec2f(0,0));
		spline2D[0].push_back(MSA::Vec2f(0.25,0.10));
		spline2D[0].push_back(MSA::Vec2f(0.75,0.50));
		spline2D[0].push_back(MSA::Vec2f(1,1));
		getCurve(curves[0],255, spline2D[0]);
		
		spline2D[1].push_back(MSA::Vec2f(0,0));
		spline2D[1].push_back(MSA::Vec2f(0.25,0.10));
		spline2D[1].push_back(MSA::Vec2f(0.75,0.50));
		spline2D[1].push_back(MSA::Vec2f(1,1));
		 getCurve(curves[1],255,  spline2D[1]);
		
		spline2D[2].push_back(MSA::Vec2f(0,0));
		spline2D[2].push_back(MSA::Vec2f(0.25,0.10));
		spline2D[2].push_back(MSA::Vec2f(0.75,0.50));
		spline2D[2].push_back(MSA::Vec2f(1,1));
		 getCurve(curves[2],255,  spline2D[2]);
		
		for(int i=0 ; i <width*height*3;  i+=3) 
		{
			
			for(int c = 0; c < 3; c++)
			{
			
				float yValue = fmax(fmin(curves[c][pixels[i+c]],1.0f),0);
				
				pixels[i+c] = round(yValue*100.0f);
			}
			
			
		}

		
		
		for(int i=0 ; i <255;  i+=1) 
		{
			for(int c = 0; c < 3; c++)
			{
		
					float yValue = fmin(curves[c][i],1.0f);
					int pos = i*3	+ round(yValue*255.0f)*width*3;
					pixels[pos] = 255;
					pixels[pos+1] = 255;
					pixels[pos+2] = 255;
			
			}

		}
	}

void filterVignette(unsigned char * pixels,int width, int height, int amount){
	
	MSA::Interpolator2D				spline2D;
	
	
	spline2D.push_back(MSA::Vec2f(0,0.1));
	spline2D.push_back(MSA::Vec2f(0.10,0.75));
	spline2D.push_back(MSA::Vec2f(0.20,0.95));
	spline2D.push_back(MSA::Vec2f(1,1));
	
	
	float longest = sqrt(sqr(width-width/2)+sqr(height - height /2));
	cout << longest;
	cout << "\n";
	
	for(int x = 0; x < width;x++)
		for(int y = 0; y < height; y ++)
		{
			int deltaX = abs(x - width/2);
			int deltaY = abs(y - height/2);
			float distanceFromMiddle = sqrt(sqr(deltaX) + sqr(deltaY));
		
			MSA::Vec2f v	= spline2D.sampleAt(1-distanceFromMiddle/longest);
			float brightness = fmin(fmax(v.y,0),1);
			int pixelPos = (y*width+x)*3;
			
			
			pixels[pixelPos] = round((float)pixels[pixelPos] * brightness);
			pixels[pixelPos+1] = round((float)pixels[pixelPos+1] * brightness);
			pixels[pixelPos+2] = round((float)pixels[pixelPos+2] * brightness);
		}
	//draw curve 
	int numsteps = 255;
	float spacing = 1.0/numsteps;
	for(float x=0 ; x <1;  x+=spacing) 
	{
		
			MSA::Vec2f v	= spline2D.sampleAt(x);
		
			if(v.y >=0 && v.y <=1)
			{
				int pos = round(x*255.0f)*3	+ round(v.y*255.0f)*width*3;
				pixels[pos] = 255;
				pixels[pos+1] = 255;
				pixels[pos+2] = 255;
				
			}
		
	}
	
}


void filterFrameit(unsigned char * pixels,int width, int height, int amount){
	//filer #2
	std::cout << "filterInvertRB applied" << endl;
	int mySize = min(width,height)-min(width,height) /15;
	int border = 10;
	
	for(int x = 0; x < width;x++)
		for(int y = 0; y < height; y ++)
		{
			
			if((x < (width/2-mySize/2) || x > (width/2+mySize/2)) ||
			   (y < (height/2-mySize/2) || y > (height/2+mySize/2))
			   )
			{
	// outside
				int pixelPos = (y*width+x)*3;
	pixels[pixelPos] = 255;
	pixels[pixelPos+1] = 255;
	pixels[pixelPos+2] = 255;
			}
		}
	
			
	
	// inside 
	// nothing
	
	// border
	
	
}


/// ########### SUPPORT FILTERS ######


float sqr(float value)
{
	return value * value;
}

// converts spline2D to an array 

void getCurve(float * curve, int resolution, MSA::Interpolator2D & spline2D)
{
	//draw curve 
	//curve = new float[resolution];
	; 
	float spacing = 1.0/(resolution*4);
	float last;
	for(float i=0 ; i <1;  i+=spacing) 
	{
		
		MSA::Vec2f v	= spline2D.sampleAt(i);
		if(v.x <=1 && v.x >= 0)
		{
			float value = min(1.0f,max(v.y,0.0f));
		curve[(int)round(v.x * resolution)] = value;
		}
		
	}
	curve[resolution] = last;
	
	cout << " \n \n";

	
}

