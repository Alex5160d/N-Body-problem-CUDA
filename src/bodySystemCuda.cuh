/*
 * bodySystemCuda.cuh
 *
 *  Created on: Dec 8, 2013
 *      Author: alex
 */

#ifndef BODYSYSTEMCUDA_CUH_
#define BODYSYSTEMCUDA_CUH_

#include "bodySystemAbstract.cuh"

/* ************************************************************************** *
 * BodySystemCUDA: All Gpu specific
 * ************************************************************************** */

class BodySystemCUDA: public BodySystemAbstract {
public:
	BodySystemCUDA(int numBodies);
	~BodySystemCUDA() {
		_finalize();
		mNumBodies = 0;
	}

	/*
	 * compute the new iteration on the current
	 * write buffer and then swap buffers
	 * to let opengl read on it
	 */
	void update();

	/*
	 * Only the color need a getter 'cause it is
	 * setted once and for all at the beginning
	 * since the rest will be modified during the demo
	 * everything will be done one GPU
	 */
	float4 *getArray(BodyArray array) {
		return mColor;
	}
	//	Used to copy data on gpu (position and velocity)
	void setArrays();
	// Set the communication between opengl and cuda
	unsigned int getReadBuffer() const {
		return mPbo[mCurrentRead];
	}

protected:
	void _initialize();
	void _finalize();

private:
	// use the GPU methods to compute the new positions and velocities
	void integrateNBodySystem();

private:
	/*
	 * Pixel buffer object
	 * to share data between opengl and cuda
	 */
	unsigned int mPbo[2];
	/*
	 * CUDA graphic ressource
	 * to set the read and write buffers
	 */
	cudaGraphicsResource *mCGRes[2];
	unsigned int mCurrentRead;
	unsigned int mCurrentWrite;

	unsigned int mBlockSize;
	int mNumBlocks;
	/*
	 * Each block will have its own shared memory
	 * with positions saved in it to make the computation
	 * faster
	 */
	int sharedMemSize;

	// bodies velocity saved in device memory
	float4 *mDVel;
	// bodies positions saved in device memory
	float4 *mDeviceCpPos[2];
};

#endif /* BODYSYSTEMCUDA_CUH_ */
