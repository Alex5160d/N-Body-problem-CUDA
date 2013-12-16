/*
 * NBodyDemo.cuh
 *
 *  Created on: Dec 14, 2013
 *      Author: alex
 */

#ifndef NBODYDEMO_CUH_
#define NBODYDEMO_CUH_

#include "bodySystemCpu.cuh"
#include "bodySystemCuda.cuh"
#include "renderer.cuh"

#include <unistd.h>
#include <stdio.h>

// check for OpenGL errors
inline
void checkGLErrors(const char *s) {
	GLenum error;
	while ((error = glGetError()) != GL_NO_ERROR)
		fprintf(stderr, "%s: error - %s\n", s, (char *) gluErrorString(error));
}

/* ************************************************************************** *
 * NBody : parameters
 * ************************************************************************** */

/*
 * Parameters for the current demo
 * which can be specified in the command line
 */
struct DemoParameters {
	DemoParameters() :
			fullscreen(false), cpu(false), bodies(4096), pause(false), zoom(
					-200), vertical(0), horizontal(0) {
	}
	// enable fullscreen
	bool fullscreen;
	// enable the cpu version of n-body problem
	bool cpu;
	// bodies number in the demo
	unsigned int bodies;
	// wait until bar space pressed
	bool pause;
	// to have a better view
	int zoom;
	int vertical;
	int horizontal;
};
//maybe a singleton would be more appropriate

/* ************************************************************************** *
 * NBodyDemo : singleton to manage the rendering and
 * 				the CUDA/CPU computation the easy way
 * ************************************************************************** */

class NBodyDemo {
public:
	//	get an instance of the singleton and init everything in the system
	static NBodyDemo* getInstance(int argc, char** argv) {
		if (mSingleton == 0) {
			mSingleton = new NBodyDemo;
			mSingleton->checkCmdLine(argc, argv);
			mSingleton->initGL(&argc, argv);
			mSingleton->init();
			mSingleton->setSystem();
			mSingleton->setRenderer();
		}
		return mSingleton;
	}
	static void kill() {
		if (mSingleton != 0) {
			delete mSingleton;
			mSingleton = 0;
		}
	}
	// glut calls
	static void reshape(int weight, int height) {
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluPerspective(60.0, (float) weight / (float) height, 0.1, 1000.0);

		glMatrixMode(GL_MODELVIEW);
		glViewport(0, 0, weight, height);
	}
	static void idle(void) {
		glutPostRedisplay();
	}
	// method called by glut to draw
	static void display() {
		// update the simulation
		if (!mSingleton->demoParams.pause) // if we choosed to control the iterations
			mSingleton->mNbodySystem->update();
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		// To see our system in as a whole, the value should be decided in a more intelligent way...
		glTranslatef(mSingleton->demoParams.horizontal, mSingleton->demoParams.vertical,
				mSingleton->demoParams.zoom);
		// We give the new values to draw
		if (mSingleton->demoParams.cpu)
			mSingleton->mRenderer->setPositions(
					mSingleton->mNbodySystem->getArray(BODYSYSTEM_POSITION),
					mSingleton->demoParams.bodies);
		else
			mSingleton->mRenderer->setPBO(
					mSingleton->mNbodySystem->getReadBuffer(),
					mSingleton->mNbodySystem->getNumBodies());
		// display particles
		mSingleton->mRenderer->display();
		glutSwapBuffers();
		glutReportErrors();
	}
	// method called by glut when a key is pressed
	static void key(unsigned char key, int, int) {
		switch (key) {
		case ' ':
			mSingleton->demoParams.pause = !mSingleton->demoParams.pause;
			break;
		case 27: // escape
		case 'q':
		case 'Q':
			cudaDeviceReset();
			exit(EXIT_SUCCESS);
		case '-':
			(mSingleton->demoParams.zoom)--;
			break;
		case '+':
			(mSingleton->demoParams.zoom)++;
			break;
		case '4':
			(mSingleton->demoParams.horizontal)++;
			break;
		case '6':
			(mSingleton->demoParams.horizontal)--;
			break;
		case '8':
			(mSingleton->demoParams.vertical)--;
			break;
		case '2':
			(mSingleton->demoParams.vertical)++;
		}

		glutPostRedisplay();
	}

private:
	NBodyDemo() :
			mNbodySystem(0), mNbodySystemCpu(0), mNbodyCuda(0), mRenderer(0), demoParams() {
	}

	~NBodyDemo() {
		if (mNbodySystemCpu) {
			delete mNbodySystemCpu;
		}

		if (mNbodyCuda) {
			delete mNbodyCuda;
		}

		delete mRenderer;
	}

	void init() {
		// we create an instance of the needed object and hide it in mNbodySystem
		if (demoParams.cpu) {
			mNbodySystemCpu = new BodySystemCPU(demoParams.bodies);
			mNbodySystem = mNbodySystemCpu;
			mNbodyCuda = 0;
		} else {
			mNbodyCuda = new BodySystemCUDA(demoParams.bodies);
			mNbodySystem = mNbodyCuda;
			mNbodySystemCpu = 0;
		}

		mRenderer = new Renderer;
		setRenderer();
	}
	//	to create the needed opengl buffers
	void setRenderer() {
		mRenderer->setColors(mNbodySystem->getArray(BODYSYSTEM_COLOR),
				mNbodySystem->getNumBodies());
	}
	//	give random values to our bodies
	void setSystem() {
		mNbodySystem->fillBodies();
		if (!demoParams.cpu)
			mNbodySystem->setArrays();
	}
	/*
	 *	Set the values depending on the command line parameters
	 */
	void checkCmdLine(int argc, char** argv) {
		int opt;
		while ((opt = getopt(argc, argv, "fcb:m")) != -1) {
			switch (opt) {
			case 'f':
				demoParams.fullscreen = true;
				break;
			case 'c':
				demoParams.cpu = true;
				break;
			case 'b':
				if ((demoParams.bodies = atoi(optarg)) < 1) {
					printf(
							"Error: number of bodies is invalid.  Value should be >= 1\n");
					exit(EXIT_FAILURE);
				}
				if (demoParams.bodies > 32) // to have a better match with our wraps size
					demoParams.bodies = 32 * (int) (demoParams.bodies / 32);
				break;
			default:
				fprintf(stderr, "-f: enable fullscreen\n"
						"-c: enable cpu solving instead of gpu\n"
						"-b: set bodies number\n");
				exit(EXIT_FAILURE);
			}
		}
	}
	// Init the opengl environment
	void initGL(int *argc, char **argv) {
		// First initialize OpenGL context, so we can properly set the GL for CUDA
		glutInit(argc, argv);
		/*
		 * GLUT_DOUBLE to swap between two buffers, one is drawn while
		 * the other is displayed, it needs more resources but give better results
		 */
		glutInitDisplayMode(GLUT_RGB | GLUT_DEPTH | GLUT_DOUBLE);
		glutInitWindowSize(720, 480);
		glutCreateWindow("TP n-body system");

		if (demoParams.fullscreen) // fullscreen is beautiful :D
			glutFullScreen();

		if (glewInit() != GLEW_OK) {
			printf("GLEW Error\n");
			exit(EXIT_FAILURE);
		} else if (!glewIsSupported("GL_VERSION_2_0 "
				"GL_VERSION_1_5 "
				"GL_ARB_multitexture "
				"GL_ARB_vertex_buffer_object")) {
			fprintf(stderr, "Required OpenGL extensions missing.");
			exit(EXIT_FAILURE);
		}

		glEnable(GL_DEPTH_TEST);
		glClearColor(0.0, 0.0, 0.0, 1.0);
		// check if the initialization was a success
		checkGLErrors("initGL");
	}

private:
	static NBodyDemo *mSingleton;
	// will hide the specificities of CUDA and CPU
	BodySystemAbstract *mNbodySystem;
	BodySystemCUDA *mNbodyCuda;
	BodySystemCPU *mNbodySystemCpu;

	Renderer *mRenderer;
	// our demo parameters
	DemoParameters demoParams;
};
NBodyDemo *NBodyDemo::mSingleton = 0;
#endif /* NBODYDEMO_CUH_ */

