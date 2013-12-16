/*
 * bodySystemCuda.cu
 *
 *  Created on: Dec 8, 2013
 *      Author: alex
 *
 */

#include "bodySystemCuda.cuh"

#include <cuda_gl_interop.h>
#include <algorithm>

/* ************************************************************************** *
 * bodySystemCUDA : Used CUDA functions
 * ************************************************************************** */

//	Compute the interaction between two bodies
__device__
float3 bodyInterac(float3 accel, float4 posFirst, float4 posSec) {
	float3 r;

	// the vector from body 1 to 0
	r.x = posSec.x - posFirst.x;
	r.y = posSec.y - posFirst.y;
	r.z = posSec.z - posFirst.z;

	//	see gravity law
	return (accel
			+ scalevec(scalevec(r,
					(float) posSec.w
							* (float) pow(rsqrt(dot(r, r) + SOFTENINGSQUARED),
									3)), 9.81f));
}

// // compute the new acceleration of all bodies
__device__ float3 computeGrav(float4 bodyPos, float4 *positions,
		int numBodies) {
	extern __shared__ float4 sharedPos[];

	float3 acc = { 0.0f, 0.0f, 0.0f };
	/*
	 * Compute the interaction of our body with all bodies of a block
	 * then do the same with the next block
	 */
	for (int i = 0; i < gridDim.x; i++) {
		// We first need to copy the positions of all bodies in the block
		sharedPos[threadIdx.x] = positions[i * blockDim.x + threadIdx.x];
		// wait for the others to have copied a body
		__syncthreads();

		// Then we'll start computing the interaction with the block
		for (unsigned int counter = 0; counter < blockDim.x; counter++)
			acc = bodyInterac(acc, bodyPos, sharedPos[counter]);
		//	When we use the shared memory we always have to sync at the end
		__syncthreads();
	}

	return acc;
}

// use the method above and compute the new positions and velocities
__global__ void integrateSys(float4* newPos, float4* oldPos, float4* vel,
		int numBodies) {
	int index = blockIdx.x * blockDim.x + threadIdx.x;

	float4 position = oldPos[index];
	float3 accel = computeGrav(position, oldPos, numBodies);

	// Now that we have the new acceleration we can update all the values
	float4 velocity = vel[index];

	// velocity is an integrator of acceleration and position is an integrator of velocity
	velocity.x += accel.x * DELTA_TIME;
	velocity.y += accel.y * DELTA_TIME;
	velocity.z += accel.z * DELTA_TIME;

	position.x += velocity.x * DELTA_TIME;
	position.y += velocity.y * DELTA_TIME;
	position.z += velocity.z * DELTA_TIME;

	/*
	 * store new position and velocity in a new
	 * location for the position because of the interaction with opengl
	 */
	newPos[index] = position;
	vel[index] = velocity;
}

/* ************************************************************************** *
 * bodySystemCUDA : Public methods
 * ************************************************************************** */

BodySystemCUDA::BodySystemCUDA(int numBodies) :
		BodySystemAbstract(numBodies), mCurrentRead(0), mCurrentWrite(1), mDVel(
				0) {
	/*
	 * Less blocks means less copies from global to shared memory
	 *
	 * 1 thread = 1 position and 1 position = 1 float4 (4*4 bytes)
	 * with 16KB of shared memory, max = 1024 bodies
	 */
	if(numBodies <= 1024)	// We have enough shared memory for all bodies (numBodies*sizeof(float4)
	{
		mBlockSize = numBodies;
	}
	else	// We divide our problem in blocks of same size and taking in account the size of a wrap
	{
		for(mBlockSize=1024; mBlockSize>=32; mBlockSize--)
			if(mBlockSize%32==0 && numBodies%mBlockSize==0)
				break;
	}
	// since the number of bodies is a multiple of 32, we'll have no remainder
	mNumBlocks = mNumBodies / mBlockSize;
	sharedMemSize = mBlockSize * sizeof(float4);
	_initialize();
}

void BodySystemCUDA::update() {

	integrateNBodySystem();

	std::swap(mCurrentRead, mCurrentWrite);
}

void BodySystemCUDA::setArrays() {
	//	we bind and fill the position buffer for cuda and opengl
	glBindBuffer(GL_ARRAY_BUFFER, mPbo[mCurrentRead]);
	glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(float4) * mNumBodies, mPos);
	//	done
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	/*
	 * the velocity won't need to be transfered to opengl
	 * so a cudamemcpy is enough
	 */
	cudaMemcpy(mDVel, mVel, mNumBodies * sizeof(float4),
			cudaMemcpyHostToDevice);
}

/* ************************************************************************** *
 * bodySystemCUDA : Protected methods
 * ************************************************************************** */

void BodySystemCUDA::_initialize() {
	unsigned int memSize = sizeof(float4) * mNumBodies;

	mPos = new float4[mNumBodies];
	mVel = new float4[mNumBodies];
	mColor = new float4[mNumBodies];

	memset(mPos, 0, mNumBodies * sizeof(float4));
	memset(mVel, 0, mNumBodies * sizeof(float4));
	memset(mColor, 0, mNumBodies * sizeof(float4));

	// create the position pixel buffer objects for rendering
	glGenBuffers(2, (GLuint *) mPbo);

	/*
	 * we fill the buffer and create the link with cuda
	 * at first old and new positions are the same so we can compute
	 * on a buffer while opengl is rendering the other
	 */
	for (int i = 0; i < 2; ++i) {
		glBindBuffer(GL_ARRAY_BUFFER, mPbo[i]);
		glBufferData(GL_ARRAY_BUFFER, memSize, mPos, GL_DYNAMIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		cudaGraphicsGLRegisterBuffer(&mCGRes[i], mPbo[i],
				cudaGraphicsMapFlagsNone);
	}
	cudaMalloc((void **) &mDVel, memSize);
}

void BodySystemCUDA::_finalize() {

	delete[] mPos;
	delete[] mVel;
	delete[] mColor;

	cudaFree(mDVel);

	cudaGraphicsUnregisterResource(mCGRes[0]);
	cudaGraphicsUnregisterResource(mCGRes[1]);
	glDeleteBuffers(2, (const GLuint *) mPbo);
}

/* ************************************************************************** *
 * bodySystemCUDA : Private methods
 * ************************************************************************** */

void BodySystemCUDA::integrateNBodySystem() {
	/*
	 * Between each update the write and read buffers are swapped
	 * so we need to remap
	 */
	cudaGraphicsResourceSetMapFlags(mCGRes[mCurrentRead],
			cudaGraphicsMapFlagsReadOnly);
	cudaGraphicsResourceSetMapFlags(mCGRes[1 - mCurrentRead],
			cudaGraphicsMapFlagsWriteDiscard);
	cudaGraphicsMapResources(2, mCGRes, 0);
	size_t bytes;
	cudaGraphicsResourceGetMappedPointer((void **) &mDeviceCpPos[mCurrentRead],
			&bytes, mCGRes[mCurrentRead]);
	cudaGraphicsResourceGetMappedPointer(
			(void **) &(mDeviceCpPos[1 - mCurrentRead]), &bytes,
			mCGRes[1 - mCurrentRead]);

	// launch the actual computation
	integrateSys<<<mNumBlocks, mBlockSize, sharedMemSize>>>(
			mDeviceCpPos[1 - mCurrentRead], mDeviceCpPos[mCurrentRead], mDVel,
			mNumBodies);
	cudaGraphicsUnmapResources(2, mCGRes, 0);
}
