/*
 * bodySystemAbstract.cu
 *
 *  Created on: Dec 4, 2013
 *      Author: alex
 *
 */

#include "bodySystemAbstract.cuh"
#include <algorithm>

/* ************************************************************************** *
 * BodySystemAbstract : methods
 * ************************************************************************** */

// Give random values to each body
void BodySystemAbstract::fillBodies() {
	/*
	 *	pos and vel are arrays of float4 to coalesce memory access
	 *	but those are local variable so we'll preserve registers space using float3 and float
	 */
	float3 point;
	float mass;
	int i = 0;

	// without this scale our bodies will be to close when their number is high
	float scale = 10 * std::max<float>(1.0f, mNumBodies / (1024.0f));
	while (i < mNumBodies) {
		// We try some random positions in intervals [-1;1]
		point.x = rand() / (float) RAND_MAX * 2 - 1;
		point.y = rand() / (float) RAND_MAX * 2 - 1;
		point.z = rand() / (float) RAND_MAX * 2 - 1;

		/*
		 *	we stay in a radius of 1
		 */
		if (distance(point, point) > 1)	//	Euclidean distance
			continue; //	try again

		// our point is alive \o/
		mass = (rand() / (float) (RAND_MAX / 5) + 1) * 1e-6; // mass (arbitrary value between 1*10-6 and 5*10-6)

		mPos[i].w = mass;
		mPos[i].x = point.x * scale;
		mPos[i].y = point.y * scale;
		mPos[i].z = point.z * scale;

		mVel[i].w = 1 / mass; // inverse mass (to compute acceleration)
		// our bodies have no speed at the beginning
		mVel[i].x = 0;
		mVel[i].y = 0;
		mVel[i].z = 0;

		// 'cause color is everything \o/
		mColor[i].w = rand() / (float) RAND_MAX;	// red
		mColor[i].x = rand() / (float) RAND_MAX;	//	green
		mColor[i].y = rand() / (float) RAND_MAX;	//	blue
		mColor[i].z = 1.0f; //	alpha
		i++;
	}
}
