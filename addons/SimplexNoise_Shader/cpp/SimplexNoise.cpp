
#include "SimplexNoise.h"
#include <Godot.hpp>

using namespace godot;
using namespace std;
void CPP_SimplexNoise::_register_methods() {
	
	register_method("get_noise2D", &CPP_SimplexNoise::get_noise2D);
	register_property<CPP_SimplexNoise, int>("_seed", &CPP_SimplexNoise::_seed, 1);
	register_property<CPP_SimplexNoise, int>("octaves", &CPP_SimplexNoise::octaves,1);
	register_property<CPP_SimplexNoise, float>("period", &CPP_SimplexNoise::period, 64);
	register_property<CPP_SimplexNoise, float>("persistence", &CPP_SimplexNoise::persistence, 0.5);
	register_property<CPP_SimplexNoise, float>("lacunarity", &CPP_SimplexNoise::lacunarity, 2.0);

}



void CPP_SimplexNoise::_init() {
	// initialize any variables here
	_seed = 1;
	octaves = 1;
	period = 64;
	persistence = 0.5;
	lacunarity = 2.0;
}


Vector3 mod289(Vector3 x) {
	return x - (x * (1.0 / 289.0)).floor() * 289.0;
}
Vector3 permute(Vector3 x, int _seed) {
	return mod289(((x * 34.0) + Vector3(_seed, _seed, _seed)) * x);
}


const float C[4] = { 0.211324865405187, //(3.0 - sqrt(3.0)) / 6.0
	0.366025403784439 // 0.5 * (sqrt(3.0) - 1.0)
	,-0.577350269189626, //- 1.0 + 2.0 * C.x
		0.024390243902439 };//  1.0 / 41.0

float evaluate2D(float x, float y, int _seed){
		float dot = (x + y) * C[1];// v.dot(Vector2(Cxy.y, Cxy.y));
		float  i[2] = { floor(x + dot)  , floor(y + dot) }; //(v + Vector2(dot, dot)).floor();
		dot = (i[0] + i[1]) * C[0]; //i.dot(Vector2(Cxy.x, Cxy.x));
		float x0[2] = { x - i[0] + dot , y - i[1] + dot }; //v - i + Vector2(dot, dot);
		//Other corners
		float i1[2];
		if (x0[0] > x0[1]) {
			i1[0] = 1.0;
			i1[1] = 0.0;
		} else {
			i1[0] = 0.0;
			i1[1] = 1.0;
		}

		float x12[4] = { x0[0] + C[0], x0[1] + C[0], x0[0] + C[2], x0[1] + C[2] }; // Like a vector4 : x0.xyxy + C.xxzz
		x12[0] -= i1[0];
		x12[1] -= i1[1];
		//Permutations
		Vector3 p = permute(permute(Vector3(i[1], i[1], i[1]) + Vector3(0.0, i1[1], 1.0), _seed)
			+ Vector3(i[0], i[0], i[0]) + Vector3(0.0, i1[0], 1.0), _seed);
		float  m[3] = { 0.5 - (x0[0] * x0[0] + x0[1] * x0[1]) , 0.5 - (x12[0] * x12[0] + x12[1] * x12[1]) , 0.5 - (x12[2] * x12[2] + x12[3] * x12[3]) };   //Vector3(0.5, 0.5, 0.5) - Vector3(  x0.dot(x0),    Vector2(x12[0], x12[1]).dot(  Vector2(x12[0], x12[1]))     , Vector2(x12[2], x12[3]).dot(Vector2(x12[2], x12[3]))    )
		for (int indx = 0; indx < 3; indx++) {
			m[indx] *= m[indx];    //m = m * m 
			m[indx] *= m[indx];
		}   
		//Gradients : 41 points uniformly over a line, mapped onto a diamond.
		//The ring size 17 * 17 = 289 is close to a multiple of 41 (41 * 7 = 287)
		p *= C[3];
		float _x[3] = { 2.0 * (p.x - floor(p.x)) - 1.0, 2.0 * (p.y - floor(p.y)) - 1.0, 2.0 * (p.z - floor(p.z)) - 1.0 }; // 2.0 * (p - p.floor()) - Vector3(1.0, 1.0, 1.0) # 2.0 * fract(p * Vector3(Czw.y, Czw.y, Czw.y)) - 1.0
		float h[3] = { abs(_x[0]) - 0.5, abs(_x[1]) - 0.5 , abs(_x[2]) - 0.5 };  //var h : Vector3 = x.abs() - Vector3(0.5, 0.5, 0.5)
		float a0[3] = { _x[0] - floor(_x[0] + 0.5), _x[1] - floor(_x[1] + 0.5), _x[2] - floor(_x[2] + 0.5) };  // var a0 : Vector3 = x - (x + Vector3(0.5, 0.5, 0.5)).floor()
		//Normalise gradients implicitly by scaling m
		//Approximation of : m *= inversesqrt(a0 * a0 + h * h);
		for (int indx = 0; indx < 3; indx++) {
			m[indx] *= 1.79284291400159 - 0.85373472095314 * (a0[indx] * a0[indx] + h[indx] * h[indx]); //m *=  Vector3(1.79284291400159, 1.79284291400159, 1.79284291400159) - 0.85373472095314 * (a0 * a0 + h * h)
		}

		//Compute final noise value at P
		return 130.0 * (m[0] * (a0[0] * x0[0] + h[0] * x0[1]) + m[1] * (a0[1] * x12[0] + h[1] * x12[1]) + m[2] * (a0[2] * x12[2] + h[2] * x12[3])); // m.dot(Vector3(a0.x * x0.x + h.x * x0.y, a0.y * x12[0] + h.y * x12[1], a0.z * x12[2] + h.z * x12[3]))

}




float CPP_SimplexNoise::get_noise2D(Vector2 v) {
	Vector2 uv = v / (period * 2.0);

	float amp = 1.0;
	float mx = 1.0;
	float sum = evaluate2D(uv.x, uv.y, _seed);

	int i = 0;
	while (++i < octaves) {
		uv *= lacunarity;
		amp *= persistence;
		mx += amp;
		sum += evaluate2D(uv.x, uv.y, _seed) * amp;
	}

	return 0.5 + ((sum / mx) * 0.5);
}
