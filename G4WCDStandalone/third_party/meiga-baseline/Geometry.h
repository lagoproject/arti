#ifndef Geometry_h
#define Geometry_h 1

#include "PhysicsConstants.h"
#include "G4ThreeVector.hh"
#include <vector>

class Geometry 
{

	public:
		Geometry();
		~Geometry();

		static G4ThreeVector ToG4Vector(const std::vector<double>* v, const double unit);
		static G4ThreeVector ToG4Vector(const std::vector<double>& v, const double unit);

};


#endif