/*
 *  filters.cpp
 *  iPhoneImagePickerExample
 *
 *  Created by Bo Peterson on 2010-10-04.
 *  Copyright 2010 Malmö högskola. All rights reserved.
 *
 */

#include "filters.h"
#include "MSAInterpolator.h"
#include "MSACore.h"


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


void filterCurves_2(IplImage * img,int width, int height,senseMaker * senses[])
{
	float amount = senses[0]->max;
	float iAmount = 1-amount;
	MSA::Interpolator2D				spline2D[3];
	MSA::InterpolationType			interpolationType	= MSA::kInterpolationCubic;
	
	
	spline2D[0].push_back(MSA::Vec2f(0,0));
	spline2D[0].push_back(MSA::Vec2f(0.25,0.20/iAmount));
	spline2D[0].push_back(MSA::Vec2f(0.75,0.80*senses[1]->valueChange));
	spline2D[0].push_back(MSA::Vec2f(1,1));
	
	spline2D[1].push_back(MSA::Vec2f(0,0));
	spline2D[1].push_back(MSA::Vec2f(0.25*amount,0.30));
	spline2D[1].push_back(MSA::Vec2f(0.75/iAmount,0.80));
	spline2D[1].push_back(MSA::Vec2f(1,1));
	
	spline2D[2].push_back(MSA::Vec2f(0,0));
	spline2D[2].push_back(MSA::Vec2f(0.25*senses[1]->valueEnergy/5,0.10));
	spline2D[2].push_back(MSA::Vec2f(0.75,0.50*amount));
	spline2D[2].push_back(MSA::Vec2f(1,1));
	
	std::cout << "filterInvertRB applied" << endl;
	
	for( int y=0; y<img->height; y++ ) { 
		uchar* ptr = (uchar*) (img->imageData + y * img->widthStep); 
		for( int x=0; x<img->width; x++ ) 
		{
			for(int c = 0; c < 3; c++)
			{
				MSA::Vec2f v	= spline2D[c].sampleAt(((float)ptr[3*x+c])/255.0f);
				float yValue = fmin(fmax(v.y,0),1);
				ptr[3*x+c] = round(yValue*255.0f);
			}
		}
	}
	
}

/**************
void filterCurves_2(IplImage * img,int width, int height, float amount)
{

	float iAmount = 1-amount;
	MSA::Interpolator2D				spline2D[3];
	MSA::InterpolationType			interpolationType	= MSA::kInterpolationCubic;
	
	
	spline2D[0].push_back(MSA::Vec2f(0,0));
	spline2D[0].push_back(MSA::Vec2f(0.25,0.20/iAmount));
	spline2D[0].push_back(MSA::Vec2f(0.75,0.80*amount));
	spline2D[0].push_back(MSA::Vec2f(1,1));
	
	spline2D[1].push_back(MSA::Vec2f(0,0));
	spline2D[1].push_back(MSA::Vec2f(0.25*amount,0.30));
	spline2D[1].push_back(MSA::Vec2f(0.75/iAmount,0.80));
	spline2D[1].push_back(MSA::Vec2f(1,1));
	
	spline2D[2].push_back(MSA::Vec2f(0,0));
	spline2D[2].push_back(MSA::Vec2f(0.25*amount,0.10));
	spline2D[2].push_back(MSA::Vec2f(0.75,0.50*amount));
	spline2D[2].push_back(MSA::Vec2f(1,1));
	
	std::cout << "filterCurves_2 applied" << endl;
	
	for( int y=0; y<img->height; y++ ) { 
		uchar* ptr = (uchar*) (img->imageData + y * img->widthStep); 
		for( int x=0; x<img->width; x++ ) 
		{
			for(int c = 0; c < 3; c++)
			{
				MSA::Vec2f v	= spline2D[c].sampleAt(((float)ptr[3*x+c])/255.0f);
				float yValue = fmin(fmax(v.y,0),1);
				ptr[3*x+c] = round(yValue*255.0f);
			}
		}
	}

 
 

}
*******************/



void filterCurves_hsv(IplImage * img,int width, int height, float amount)
{
	amount = (1.0f-min(1.0f,amount*2))/2.0f;
	cout << "\n";
	cout << amount;
	cout << "\n";
	float iAmount = 1.0f- amount;
	MSA::Interpolator2D				spline2D[3];
	MSA::InterpolationType			interpolationType	= MSA::kInterpolationCubic;
	
	
	spline2D[0].push_back(MSA::Vec2f(0,0.80/iAmount));
	spline2D[0].push_back(MSA::Vec2f(0.25,0.30/iAmount));
	spline2D[0].push_back(MSA::Vec2f(0.75,0.50*iAmount));
	spline2D[0].push_back(MSA::Vec2f(1,1*iAmount));
	
	spline2D[1].push_back(MSA::Vec2f(0,0.80*iAmount));
	spline2D[1].push_back(MSA::Vec2f(0.25,0.20*iAmount));
	spline2D[1].push_back(MSA::Vec2f(0.75,0.90/iAmount));
	spline2D[1].push_back(MSA::Vec2f(1,0.3*iAmount));
	
	spline2D[2].push_back(MSA::Vec2f(0,0));
	//spline2D[2].push_back(MSA::Vec2f(0.25*iamount,0.10));
	//spline2D[2].push_back(MSA::Vec2f(0.75,0.50*iamount));
	spline2D[2].push_back(MSA::Vec2f(1,1));
	
	std::cout << "filterCurves_hsv applied" << endl;
	
	for( int y=0; y<img->height; y++ ) { 
		uchar* ptr = (uchar*) (img->imageData + y * img->widthStep); 
		for( int x=0; x<img->width; x++ ) 
		{
			for(int c = 0; c < 3; c++)
			{
				MSA::Vec2f v	= spline2D[c].sampleAt(((float)ptr[3*x+c])/255.0f);
				float yValue = fmin(fmax(v.y,0),1);
				ptr[3*x+c] = round(yValue*255.0f);
			}
		}
	}
	
	//draw curve 
	char * pixels = img->imageData;
		int numsteps = 255;
	 float spacing = 1.0/numsteps;
	 for(float x=0 ; x <1;  x+=spacing) 
	 {
	 for(int c = 0; c < 3; c++)
	 {
	 MSA::Vec2f v	= spline2D[c].sampleAt(x);
	 //cout << round(v.y*100);
	 //cout << '\n';
	 if(v.y >=0 && v.y <=1)
	 {
	 int pos = round(x*255.0f)*3		+round(v.y*255.0f)*width*3;
	 pixels[pos] = 255;
	 pixels[pos+1] = 255;
	 pixels[pos+2] = 255;
	 
	 }
	 }
	 
	 }
}

void filterVignette_2(IplImage * img,int width, int height, int amount){
	
	MSA::Interpolator2D				spline2D;
	
	
	spline2D.push_back(MSA::Vec2f(0,0.1));
	spline2D.push_back(MSA::Vec2f(0.10,0.75));
	spline2D.push_back(MSA::Vec2f(0.20,0.95));
	spline2D.push_back(MSA::Vec2f(1,1));
	
	
	float longest = sqrt(sqr(width-width/2)+sqr(height - height /2));

	
	for( int y=0; y<img->height; y++ ) { 
		uchar* ptr = (uchar*) (img->imageData + y * img->widthStep); 
		for( int x=0; x<img->width; x++ ) 
		{
			
			int deltaX = abs(x - width/2);
			int deltaY = abs(y - height/2);
			float distanceFromMiddle = sqrt(sqr(deltaX) + sqr(deltaY));
			
			MSA::Vec2f v	= spline2D.sampleAt(1-distanceFromMiddle/longest);
			float brightness = fmin(fmax(v.y,0),1);
			int pixelPos = (y*width+x)*3;
		
			ptr[3*x] = round((float)ptr[3*x] * brightness);
			ptr[3*x+1] = round((float)ptr[3*x+1] * brightness);
			ptr[3*x+2] = round((float)ptr[3*x+2]* brightness);

			
			
		
		}
	}

	
	/*
	//draw curve 
	int numsteps = 255;
	float spacing = 1.0/numsteps;
	for(float x=0 ; x <1;  x+=spacing) 
	{
		
		MSA::Vec2f v	= spline2D.sampleAt(x);
		cout << round(v.y*100);
		cout << '\n';
		if(v.y >=0 && v.y <=1)
		{
			int pos = round(x*255.0f)*3		+round(v.y*255.0f)*width*3;
			pixels[pos] = 255;
			pixels[pos+1] = 255;
			pixels[pos+2] = 255;
			
		}
		
	}*/
	
}

void ant(unsigned char * pixels,int posX, int posY,float dir, int width, int height, int depth, float amount)
{
    cout << "entering ant, depth: " << depth << endl;
	if(depth> 0 && posX < width -20 && posY<height -20 && posX > 20 && posY > 20)
	{
        cout << "-";
		for(int i =0; i < 10; i ++)
		{
            cout << "/";
            int value1 =  pixels[(posY*width + posX)*3]+ pixels[(posY*width + posX)*3+1] + pixels[(posY*width + posX)*3+2] ;
            int smallestDiff = 1000;
            int tHor = 1;
            int tVer = 1;
                int tDir = dir;
            posY -1;
            int values[3][3];
                
            /*
            program stuck like this:
            ant iteration 0
            entering ant, depth: 6
            ant iteration 1
            entering ant, depth: 6
            -/___/___/___re-cursing:) 
            entering ant, depth: 5
            -/_______________
            */
                
            for(float angle = -PI/2.0f; angle < PI/2.0f;angle+=PI/4)
            {
                cout << "_" << angle;
                int ver = round(cos(angle+dir) * 1.0f);
                int hor =  round(sin(angle+dir) * 1.0f);
                values[ver][hor] = 
                pixels[((posY+ver)*width + posX+hor)*3 ]+
                pixels[((posY+ver)*width + posX+hor)*3+1]+
                pixels[((posY+ver)*width + posX+hor)*3+2];
                if(abs(value1 -values[ver][hor]) < smallestDiff)
                {
                    smallestDiff = abs(value1 -values[ver][hor]);
                    tHor = hor;
                    tVer = ver;
                    tDir = dir + angle;
                }
            }
            
        
            posY = posY + tVer;
            posX = posX + tHor;
            
            
            pixels[((posY)*width + posX)*3 ] = 255;//här blev det exec bad access
            pixels[((posY)*width + posX)*3+1] = 255;
            pixels[((posY)*width + posX)*3+2] = 255;
            
            if(ofRandom(0,100)<20)
            {
                cout << "re-cursing:) " << endl;
                ant(pixels,posX+ round(ofRandom(-2, 2)), posY+ round(ofRandom(-2, 2)),tDir,width, height, depth-1,amount);
            }	
		
		}
	
	}
}


void filterCurves(unsigned char * pixels,int width, int height, float amount)
	{
		
		float iAmount = 1-amount;
		MSA::Interpolator2D				spline2D[3];
		MSA::InterpolationType			interpolationType	= MSA::kInterpolationCubic;

		
		spline2D[0].push_back(MSA::Vec2f(0,0));
		spline2D[0].push_back(MSA::Vec2f(0.25,0.20/iAmount));
		spline2D[0].push_back(MSA::Vec2f(0.75,0.80*amount));
		spline2D[0].push_back(MSA::Vec2f(1,1));
		
		spline2D[1].push_back(MSA::Vec2f(0,0));
		spline2D[1].push_back(MSA::Vec2f(0.25*amount,0.30));
		spline2D[1].push_back(MSA::Vec2f(0.75/iAmount,0.80));
		spline2D[1].push_back(MSA::Vec2f(1,1));
		
		spline2D[2].push_back(MSA::Vec2f(0,0));
		spline2D[2].push_back(MSA::Vec2f(0.25*amount,0.10));
		spline2D[2].push_back(MSA::Vec2f(0.75,0.50*amount));
		spline2D[2].push_back(MSA::Vec2f(1,1));
		
		std::cout << "filterInvertRB applied" << endl;
		for(int i=0 ; i <width*height*3;  i+=3) 
		{
			for(int c = 0; c < 3; c++)
			{
				MSA::Vec2f v	= spline2D[c].sampleAt(((float)pixels[i+c])/255.0f);
				float yValue = fmin(fmax(v.y,0),1);
				pixels[i+c] = round(yValue*255.0f);
			}
			
			
			// simple version instead of interpolation.
		/*	//R
			pixels[i] = fabs((float)pixels[i]*((float)pixels[i]/(float)255));
			//G
			pixels[i+1] = fabs((float)pixels[i]*((float)pixels[i]/(float)355));
			//B
			pixels[i+2] = fabs((float)pixels[i]*((float)pixels[i]/(float)155));*/
		}

		
		//draw curve 
		int numsteps = 255;
		float spacing = 1.0/numsteps;
		for(float x=0 ; x <1;  x+=spacing) 
		{
			for(int c = 0; c < 3; c++)
			{
			MSA::Vec2f v	= spline2D[c].sampleAt(x);
			cout << round(v.y*100);
			cout << '\n';
			if(v.y >=0 && v.y <=1)
			{
				int pos = round(x*255.0f)*3		+round(v.y*255.0f)*width*3;
				pixels[pos] = 255;
				pixels[pos+1] = 255;
				pixels[pos+2] = 255;
				
			}
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
			
			if(x==height/2)
			{
				cout << distanceFromMiddle;
				cout << "	";
				cout << v.y;
				cout << "\n";
			}
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
			cout << round(v.y*100);
			cout << '\n';
			if(v.y >=0 && v.y <=1)
			{
				int pos = round(x*255.0f)*3		+round(v.y*255.0f)*width*3;
				pixels[pos] = 255;
				pixels[pos+1] = 255;
				pixels[pos+2] = 255;
				
			}
		
	}
	
}

float sqr(float value)
{
	return value * value;
}

void filterFrameit(unsigned char * pixels,int width, int height, int amount){
	int mySize = min(width,height)-min(width,height) /15;
	
	for(int x = 0; x < width;x++){
		for(int y = 0; y < height; y ++)
		{
			
			if((x < (width/2-mySize/2) || x > (width/2+mySize/2)) ||
			   (y < (height/2-mySize/2) || y > (height/2+mySize/2))) {
                // outside
				int pixelPos = (y*width+x)*3;
                pixels[pixelPos] = 255;
                pixels[pixelPos+1] = 255;
                pixels[pixelPos+2] = 255;
			}           
        }
    }

	
			
	
	// inside 
	// nothing
	
	// border
	
	
}
