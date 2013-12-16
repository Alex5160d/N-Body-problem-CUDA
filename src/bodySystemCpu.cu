/*
 * bodySystemCpu.cu
 *
 *  Created on: Dec 4, 2013
 *      Author: alex
 *
 */

#include "bodySystemCpu.cuh"

/* ************************************************************************** *
 * bodySystemCpu : Public methods
 * ************************************************************************** */

void BodySystemCPU::update() {
	integrateSys();
}

float4 *BodySystemCPU::getArray(BodyArray array) {
	switch (array) {
	default:
	case BODYSYSTEM_POSITION:
		return mPos;
	case BODYSYSTEM_VELOCITY:
		return mVel;
	case BODYSYSTEM_COLOR:
			return mColor;
	}
}

/* ************************************************************************** *
 * bodySystemCpu : Protected methods
 * ************************************************************************** */

void BodySystemCPU::_initialize() {
	mPos = new float4[mNumBodies];
	mVel = new float4[mNumBodies];
	mColor = new float4[mNumBodies];
	mAcc = new float3[mNumBodies];

	memset(mPos, 0, mNumBodies * sizeof(float4));
	memset(mVel, 0, mNumBodies * sizeof(float4));
	memset(mColor, 0, mNumBodies * sizeof(float4));
	memset(mAcc, 0, mNumBodies * sizeof(float3));
}

void BodySystemCPU::_finalize() {
	delete[] mPos;
	delete[] mVel;
	delete[] mColor;
	delete[] mAcc;
}

/* ************************************************************************** *
 * bodySystemCpu : Private methods
 * ************************************************************************** */

void BodySystemCPU::computeGrav() {
	// loop on every body \o/
	for (int i = 0; i < mNumBodies; i++) {
		float3 acc = { 0, 0, 0 };
		//	for each body, we compute his interaction with each other
		for (int j = 0; j < mNumBodies; j++)
			bodyInterac(acc, mPos[i], mPos[j]);

		//	the new acceleration
		mAcc[i] = acc;
	}
}

void BodySystemCPU::integrateSys() {
	computeGrav();
	/*
	 * we need those local variables make the computation easier
	 * by dividing between mass and position/velocity
	 */
	float3 lpos, lvel;
	for (int i = 0; i < mNumBodies; ++i) {
		// we save the old values
		lpos.x = mPos[i].x;
		lpos.y = mPos[i].y;
		lpos.z = mPos[i].z;

		lvel.x = mVel[i].x;
		lvel.y = mVel[i].y;
		lvel.z = mVel[i].z;

		// new velocity = old velocity + acceleration * deltaTime
		lvel = lvel + scalevec(mAcc[i], DELTA_TIME);

		// new position = old position + velocity * deltaTime
		lpos = lpos + scalevec(lvel, DELTA_TIME);

		mPos[i].x = lpos.x;
		mPos[i].y = lpos.y;
		mPos[i].z = lpos.z;

		mVel[i].x = lvel.x;
		mVel[i].y = lvel.y;
		mVel[i].z = lvel.z;
	}
}

void BodySystemCPU::bodyInterac(float3& accel, float4 const& posFirst, float4 const& posSec) {
	float3 r;

	// the vector going from body 1 to 0
	r.x = posSec.x - posFirst.x;
	r.y = posSec.y - posFirst.y;
	r.z = posSec.z - posFirst.z;

	//	see gravity law
	accel = accel + scalevec(scalevec(r, (float) posSec.w * (float) pow(rsqrt(dot(r, r) + SOFTENINGSQUARED), 3)), 9.81f);
}
