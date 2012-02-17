/*
 *  filters.h
 *  iPhoneImagePickerExample
 *
 *  Created by Bo Peterson on 2010-10-04.
 *  Copyright 2010 Malmö högskola. All rights reserved.
 *
 */

#include "MSAInterpolator.h"
#include "MSACore.h"
#include "ofMain.h"
#include "ofxOpenCv.h"
#include "senseMaker.h"
void filterSelector(int filternumber, unsigned char * pixels,int width, int height, int amount);
void filterGeneral(unsigned char * pixels,int width, int height, int amount);
void filterInvert(unsigned char * pixels,int width, int height, int amount);
void filterInvertRB(unsigned char * pixels,int width, int height, int amount);
void filterCurves(unsigned char * pixels,int width, int height, float amount);
void filterCurves_2(IplImage * pixels,int width, int height, senseMaker * senses[]);
void filterCurves_crazy(IplImage * pixels,int width, int height, senseMaker * senses[]);
void filterCurves_hsv(IplImage * pixels,int width, int height,senseMaker * senses[]);

void filterGlitch(IplImage * pixels,int width, int height,senseMaker * senses[]);

void filterVignette(unsigned char * pixels,int width, int height, int amount);
void filterVignette_2(IplImage * img,int width, int height, int amount);
void ant(unsigned char * pixels,int posX, int posY,float dir, int width, int height,  int depth,senseMaker * senses[]);
float sqr(float value);
void filterFrameit(unsigned char * pixels,int width, int height, int amount);
void getCurve(float * curve, int resolution, MSA::Interpolator2D &spline2D);
