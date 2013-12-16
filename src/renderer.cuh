/*
 * renderer.cuh
 *
 *  Created on: Dec 8, 2013
 *      Author: alex
 *
 */

#ifndef RENDERER_CUH_
#define RENDERER_CUH_

#include "bodySystemAbstract.cuh"

/* ************************************************************************** *
 * Renderer : To render our pixels with opengl
 * ************************************************************************** */

class Renderer {
public:
	Renderer();
	~Renderer();

	//	bodies position
	void setPositions(float4 *pos, int numParticles);
	//	bodies color
	void setColors(float4 *color, int numParticles);
	//	get pbo from cuda part
	void setPBO(unsigned int pbo, int numParticles);

	//	draw everything
	void display();

protected:
	void _initGL();
	void _createTexture(int resolution = 32);
	void _drawPoints();

protected:
	float4 *mPos;// our rendering class will have its own pointer on bodies position
	int mNumParticles;	// number of bodies

	float mSpriteSize;	// the size of bodies to draw

	unsigned int mVertexShader;
	unsigned int mVertexShaderPoints;
	unsigned int mPixelShader;

	unsigned int mProgramSprites;
	unsigned int mTexture;// the texture for gaussian blur
	unsigned int mPbo;	//	Pixel buffer object, to link opengl and cuda
	unsigned int mVboColor;	//	Vertex buffer object to set bodies color

	float mBaseColor[4];
};

#endif
