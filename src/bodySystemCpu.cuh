/*
 * bodySystemCpu.h
 *
 *  Created on: Dec 4, 2013
 *      Author: alex
 *
 *	The CPU version of the n-body problem
 *
 */

#ifndef BODYSYSTEMCPU_CUH_
#define BODYSYSTEMCPU_CUH_

#include "bodySystemAbstract.cuh"

/* ************************************************************************** *
 * BodySystemCpu: All Cpu specific
 * ************************************************************************** */

class BodySystemCPU: public BodySystemAbstract {
public:
	BodySystemCPU(int numBodies) :
			BodySystemAbstract(numBodies), mAcc(0) {
		_initialize();
	}
	~BodySystemCPU() {
		_finalize();
		mNumBodies = 0;
	}

	// Those two methods are of no use here
	unsigned int getReadBuffer() const{ return 0;}
	void   setArrays(){}

	// We'll only need to compute a new iteration here
	void update();

	// Used by opengl to get the color and the new positions at each iteration
	float4 *getArray(BodyArray array);

protected:
	void _initialize();
	void _finalize();

private:
	// The interaction of a body with anothers
	void bodyInterac(float3& accel, float4 const& posFirst, float4 const& posSec);
	// compute the new acceleration of all bodies
	void computeGrav();
	// use the method above and compute the new positions and velocities
	void integrateSys();

private:
	/*
	 * Since working with arrays is easier and the memory isn't such
	 * a problem on CPU, we'll keep the acceleration
	 */
	float3 *mAcc;
};

#endif
