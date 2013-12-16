/*
 * bodySystemAbstract.cuh
 *
 *  Created on: Dec 4, 2013
 *      Author: alex
 *
 *	Here are gathered abstract bases for CPU and GPU versions and functions for float3
 *
 */

#ifndef BODYSYSTEMABSTRACT_CUH_
#define BODYSYSTEMABSTRACT_CUH_
#include <GL/glew.h>
#include <GL/freeglut.h>

// time elapsed between each update of our system
#define DELTA_TIME 1.0f
// To avoid the force between two bodies growing indefinitely, which has no physical sense
#define SOFTENINGSQUARED (0.0001f * 0.0001f)

/*
 * Computation will be done on large arrays of positions and velocities
 * so we create functions to automate the mallocs and memcpy
 */
enum BodyArray {
	BODYSYSTEM_POSITION, BODYSYSTEM_VELOCITY, BODYSYSTEM_COLOR
};

/* ************************************************************************** *
 * float3 for CPU and GPU: Operators
 * ************************************************************************** */

 __device__ __host__
inline float3 operator+(float3 const& v1, float3 const& v2) {
	float3 v = v1;

	v.x += v2.x;
	v.y += v2.y;
	v.z += v2.z;

	return v;
}

inline float3 operator-(float3 const& v1, float3 const& v2) {
	float3 v = v1;

	v.x -= v2.x;
	v.y -= v2.y;
	v.z -= v2.z;

	return v;
}

// vector * scalar
__device__ __host__
inline float3 scalevec(float3 const& v1, float scalar) {
	float3 v = v1;
	v.x *= scalar;
	v.y *= scalar;
	v.z *= scalar;
	return v;
}

// dot product
__device__ __host__
inline float dot(float3 const& v1, float3 const& v2) {
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

// Euclidean distance
__device__ __host__
inline float distance(float3 const& v1, float3 const& v2) {
	float3 v;
	v.x = v2.x - v1.x;
	v.y = v2.y - v1.y;
	v.z = v2.z - v1.z;
	return sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
}

/* ************************************************************************** *
 * BodySystemAbstract : Abstract class and methods implementation
 * ************************************************************************** */

// BodySystem abstract base class
class BodySystemAbstract {
public:
	BodySystemAbstract(int numBodies) : mNumBodies(numBodies), mPos(0), mVel(0), mColor(0){}
	virtual ~BodySystemAbstract() {
	}
	// Update the velocity, force and position over the time
	virtual void update() = 0;

	//to get and set positions, velocities and colors
	virtual float4 *getArray(BodyArray array) = 0;
	virtual void   setArrays() = 0;	//	this one is only needed for the CUDA part

	//only needed for the CUDA part, allow cuda and opengl to communicate
	virtual unsigned int getReadBuffer() const = 0;

	// Return the number of bodies we are working with
	unsigned int getNumBodies() const {
		return mNumBodies;
	}

	// To fill our system before the demo
	void fillBodies();

protected:
	// Will alloc the needed memory
	virtual void _initialize() = 0;
	// Free everything
	virtual void _finalize() = 0;

protected:
	// number of bodies we are working with
	unsigned int mNumBodies;

	// bodies coordinates
	float4 *mPos;
	// bodies velocity
	float4 *mVel;
	// bodies colors
	float4 *mColor;
};

#endif /* BODYSYSTEMABSTRACT_CUH_ */
