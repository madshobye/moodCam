/*
 *  senseMaker.cpp
 *  contextphoto
 *
 *  Created by mads hobye on 2/4/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "senseMaker.h"
#include "ofMain.h"
#define AVG 0
#define POPUP 1
#define POPDOWN 2


void senseMaker::init(float speedGeneralInit,float speedGeneralUpInit,float speedGeneralDownInit,float speedGeneralMaxMinInit,float speedEnergyInit,float fsampInit)
{
	
	valueFast = 0;
	valueSlow = 0;
	fsamp=fsampInit;
	valueEnergy = 0;
	speedGeneral = speedGeneralInit;
	speedGeneralUp = speedGeneralUpInit; //mads: speedGeneral*0.001
	speedGeneralDown =speedGeneralDownInit; //mads: speedGeneral*0.0001
	speedGeneralMaxMin = speedGeneralMaxMinInit; //mads: speedGeneral*0.00001
	speedEnergy = speedEnergyInit;
	isPeak = false;
	numSamples=0;
	max=0;
	min=0;
}
void senseMaker::sampling(float value)
{
	valueFast = calcAvg(value, valueFast, speedGeneral);
	valueSlow = calcAvg(value, valueSlow, speedGeneralUp,speedGeneralDown);
//	valueEnergy = calcAvg(valueEnergy + valueFast/fsamp,valueEnergy,speedGeneralUp,speedEnergy);
	valueEnergy = calcAvg(0,valueEnergy + valueFast/fsamp,speedGeneralUp,speedEnergy);

	float oldValueChange = valueChange;
	valueChange = calcAvg(fabs(valueFast - valueSlow), valueChange, speedGeneral,speedGeneralDown);
	if (oldValueChange /valueChange < 0.90)
	{
		beatDetected = true;
	}
		
	if(numSamples > 10)
	{
		max = calcAvg(valueFast, max, speedGeneral,speedGeneralMaxMin);
		min = calcAvg(valueFast, min, speedGeneralMaxMin,speedGeneral);
	}
	numSamples++;
	
	
}

bool senseMaker::isBeat()
{
	bool tmpBeat = beatDetected;
	beatDetected = false;
	return tmpBeat;
	
	
}
	

float senseMaker::calcAvg(float value, float valueAvg, float speed)
{
	return calcAvg( value,  valueAvg, speed, speed);
	
}
float senseMaker::calcAvg(float value, float valueAvg, float speedUp, float speedDown)
{
	if(!(speedUp < 1 && speedDown < 1))
	{
		cout << "speed is wrong";
	}
	if(value > valueAvg)
	{
		return valueAvg * (1-speedUp) + value * (speedUp);
	}
	if(value <= valueAvg)
	{
		return valueAvg * (1-speedDown) + value * (speedDown);
		
	}

}
