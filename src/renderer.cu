/*
 * renderer.cu
 *
 *  Created on: Dec 8, 2013
 *      Author: alex
 *
 */

#include "renderer.cuh"

/* ************************************************************************** *
 * Renderer : Public methods
 * ************************************************************************** */

// Those are values from research and experiments, should be setted in a more intelligent way...
Renderer::Renderer() :
		mPos(0), mNumParticles(0), mSpriteSize(2.0f), mVertexShader(0), mVertexShaderPoints(
				0), mPixelShader(0), mProgramSprites(0), mTexture(0), mPbo(0), mVboColor(
				0) {
	mBaseColor[0] = 1.0f;
	mBaseColor[1] = 0.6f;
	mBaseColor[2] = 0.3f;
	mBaseColor[3] = 1.0f;
	_initGL();
}

Renderer::~Renderer() {
	mPos = 0;
}

// bind and fill the opengl buffer using our bodies positions
void Renderer::setPositions(float4 *pos, int numParticles) {
	mPos = pos;
	mNumParticles = numParticles;

	if (!mPbo) {
		glGenBuffers(1, (GLuint *) &mPbo);
	}

	glBindBuffer(GL_ARRAY_BUFFER_ARB, mPbo);
	glBufferData(GL_ARRAY_BUFFER_ARB, numParticles * sizeof(float4), pos,
			GL_STATIC_DRAW_ARB);
	glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
}

//	same for the colors
void Renderer::setColors(float4 *color, int numParticles) {
	glBindBuffer(GL_ARRAY_BUFFER_ARB, mVboColor);
	glBufferData(GL_ARRAY_BUFFER_ARB, numParticles * sizeof(float4), color,
			GL_STATIC_DRAW_ARB);
	glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
}

void Renderer::setPBO(unsigned int pbo, int numParticles) {
	mPbo = pbo;
	mNumParticles = numParticles;
}

void Renderer::display() {
	// setup point sprites
	glEnable(GL_POINT_SPRITE_ARB);
	glTexEnvi(GL_POINT_SPRITE_ARB, GL_COORD_REPLACE_ARB, GL_TRUE);
	glEnable(GL_VERTEX_PROGRAM_POINT_SIZE_NV);
	glPointSize(mSpriteSize);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	glEnable(GL_BLEND);
	glDepthMask(GL_FALSE);

	glUseProgram(mProgramSprites);
	GLuint texLoc = glGetUniformLocation(mProgramSprites, "splatTexture");
	glUniform1i(texLoc, 0);

	glActiveTextureARB(GL_TEXTURE0_ARB);
	glBindTexture(GL_TEXTURE_2D, mTexture);

	glColor3f(1, 1, 1);
	glSecondaryColor3fv(mBaseColor);

	_drawPoints();

	glUseProgram(0);

	glDisable(GL_POINT_SPRITE_ARB);
	glDisable(GL_BLEND);
	glDepthMask(GL_TRUE);
}

/* ************************************************************************** *
 * Renderer : Protected methods
 * ************************************************************************** */

void Renderer::_drawPoints() {
	if (!mPbo) {
		glBegin(GL_POINTS);
		{
			//	A small trick to draw our vertex3 with float4
			int k = 0;
			for (int i = 0; i < mNumParticles; ++i) {
				glVertex3fv((float*) &mPos[k]);
				k += 4;
			}
		}
		glEnd();
	} else {	// so much simple with pbo
		glEnableClientState(GL_VERTEX_ARRAY);

		glBindBufferARB(GL_ARRAY_BUFFER_ARB, mPbo);

		glVertexPointer(4, GL_FLOAT, 0, 0);

		glEnableClientState(GL_COLOR_ARRAY);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, mVboColor);
		glColorPointer(4, GL_FLOAT, 0, 0);

		glDrawArrays(GL_POINTS, 0, mNumParticles);
		glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
}

const char vertexShaderPoints[] =
		{
				"void main()                                                            						\n"
						"{                                                                      				\n"
						"    vec4 vertex = vec4(gl_Vertex.xyz, 1.0);  			                				\n"
						"    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vertex;   				\n"
						"    gl_FrontColor = gl_Color;                                          				\n"
						"}                                                                      				\n" };

const char vertexShader[] =
		{
				"void main()                                                            						\n"
						"{                                                                      				\n"
						"    float pointSize = 500.0 * gl_Point.size;                           				\n"
						"    vec4 vertex = gl_Vertex;															\n"
						"    vertex.w = 1.0;																	\n"
						"    vec3 pos_eye = vec3 (gl_ModelViewMatrix * vertex);                 				\n"
						"    gl_PointSize = max(1.0, pointSize / (1.0 - pos_eye.z));            				\n"
						"    gl_TexCoord[0] = gl_MultiTexCoord0;                                				\n"
						"    gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * vertex;   				\n"
						"    gl_FrontColor = gl_Color;                                          				\n"
						"    gl_FrontSecondaryColor = gl_SecondaryColor;                        				\n"
						"}                                                                      				\n" };

const char pixelShader[] =
		{
				"uniform sampler2D splatTexture;                                        						\n"
						"void main()                                                            				\n"
						"{                                                                      				\n"
						"    vec4 colorSec = gl_SecondaryColor;                                 				\n"
						"    vec4 color = (0.6 + 0.4 * gl_Color) * texture2D(splatTexture, gl_TexCoord[0].st); 	\n"
						"    gl_FragColor = color * colorSec;													\n"
						"}                                                                      				\n" };

// Will create and attach all the shader to apply on our image
void Renderer::_initGL() {
	mVertexShader = glCreateShader(GL_VERTEX_SHADER);
	mVertexShaderPoints = glCreateShader(GL_VERTEX_SHADER);
	mPixelShader = glCreateShader(GL_FRAGMENT_SHADER);

	const char *vertex = vertexShader;
	const char *pixel = pixelShader;
	glShaderSource(mVertexShader, 1, &vertex, 0);
	glShaderSource(mPixelShader, 1, &pixel, 0);
	const char *vp = vertexShaderPoints;
	glShaderSource(mVertexShaderPoints, 1, &vp, 0);

	glCompileShader(mVertexShader);
	glCompileShader(mVertexShaderPoints);
	glCompileShader(mPixelShader);

	mProgramSprites = glCreateProgram();
	glAttachShader(mProgramSprites, mVertexShader);
	glAttachShader(mProgramSprites, mPixelShader);
	glLinkProgram(mProgramSprites);

	_createTexture();

	glGenBuffers(1, (GLuint *) &mVboColor);
	glBindBuffer(GL_ARRAY_BUFFER_ARB, mVboColor);
	glBufferData(GL_ARRAY_BUFFER_ARB, mNumParticles * sizeof(float4), 0,
			GL_STATIC_DRAW_ARB);
	glBindBuffer(GL_ARRAY_BUFFER_ARB, 0);
}

/*
 *	Build a beautiful texture to have a gaussian blur on our bodies
 *
 */

// Gaussian approximation
inline float evalHermite(float dist) {
	return (2 * pow(dist, 3) - 3 * pow(dist, 2) + 1);
}

// Create the gaussian blur applied to each body
uchar4 *createGaussianMap(int resolution) {
	/*
	 * Red/Green/Blue/Alpha values at each coordinate (at a distance of 1 from the body)
	 * with a step of 2/resolution
	 */
	uchar4 *texturMatrix = new uchar4[resolution * resolution];
	// the x coordinate, y coordinate, y squarred to compute the distance
	float x, y, ySquarred, dist;
	// The y and x value are between -1 and 1 (coordinates system centered on the body)
	float step = 2.0f / resolution;
	y = -1.0f;
	//
	int j = 0;

	for (int a = 0; a < resolution; a++, y += step) {
		ySquarred = pow(y, 2);
		x = -1.0f;

		for (int b = 0; b < resolution; b++, x += step, j++) {
			dist = (float) sqrtf(pow(x, 2) + ySquarred); // euclidean distance

			if (dist > 1) // we keep a radius of 1
				dist = 1;
			// we compute the color values for this distance
			texturMatrix[j].w = texturMatrix[j].x = texturMatrix[j].y =
					texturMatrix[j].z =
							(unsigned char) (evalHermite(dist) * 255);
		}
	}

	return (texturMatrix);
}

void Renderer::_createTexture(int resolution) {
	uchar4 *colorMap = createGaussianMap(resolution);
	glGenTextures(1, (GLuint *) &mTexture);
	glBindTexture(GL_TEXTURE_2D, mTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP_SGIS, GL_TRUE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
			GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, resolution, resolution, 0, GL_RGBA,
			GL_UNSIGNED_BYTE, colorMap);

}
