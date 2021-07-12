#pragma once

//#ifndef GDEXAMPLE_H
//#define GDEXAMPLE_H

#include <Godot.hpp>
#include <Resource.hpp>
#include <vector>

using namespace std;
namespace godot {

	class CPP_SimplexNoise : public Resource
	{
		GODOT_CLASS(CPP_SimplexNoise, Resource);



		int _seed;
		int octaves;
		float period;
		float persistence;
		float lacunarity;

	public:

		static void _register_methods();

		float get_noise2D(Vector2 v);

		void _init();

	};
}