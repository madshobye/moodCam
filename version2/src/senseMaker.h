/*
 *  senseMaker.h
 *  contextphoto
 *
 *  Created by mads hobye on 2/4/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once
class senseMaker{


public:
	long numSamples;
	float speedGeneral,speedGeneralUp,speedGeneralDown,speedGeneralMaxMin,speedEnergy;
	float valueFast;
	float valueSlow;
	float valueChange;	
	float valueEnergy;
	float max;
	float min;
	float fsamp;
	
	void sampling(float value);
	void init(float speedGeneralInit,float speedGeneralUpInit,float speedGeneralDownInit, float speedGeneralMaxMinInit,float speedEnergyInit,float fsampInit);
	float calcAvg(float value, float valueAvg, float speedUp, float speedDown);
	float calcAvg(float value, float valueAvg, float speed);
	bool isBeat();
	
	bool isPeak;
	bool beatDetected;
	float changeSlow;
	
	
};