/*
 *	main.cpp
 *
 *  Created on: Dec 4, 2013
 *      Author: alex
 *
 */

#include "NBodyDemo.cuh"

/* ************************************************************************** *
 * NBody : main
 * ************************************************************************** */

int main(int argc, char **argv) {
	NBodyDemo *demo = NBodyDemo::getInstance(argc, argv);

	// Set all needed glut callbacks
	glutDisplayFunc(NBodyDemo::display);
	glutKeyboardFunc(NBodyDemo::key);
	glutReshapeFunc(NBodyDemo::reshape);
	glutIdleFunc(NBodyDemo::idle);
	//	launch the main loop which will catch the events
	glutMainLoop();

	NBodyDemo::kill();
	exit(EXIT_SUCCESS);
}
