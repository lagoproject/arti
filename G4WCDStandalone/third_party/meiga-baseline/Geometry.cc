// implementation of class Geometry
#include "Geometry.h"

Geometry::Geometry()
{

}

G4ThreeVector
Geometry::ToG4Vector(const std::vector<double>* v, const double unitConversion)
{
 	return G4ThreeVector(
      unitConversion * v->at(0),
      unitConversion * v->at(1),
      unitConversion * v->at(2)
    );
}

G4ThreeVector
Geometry::ToG4Vector(const std::vector<double>& v, const double unitConversion)
{
 	return G4ThreeVector(
      unitConversion * v.at(0),
      unitConversion * v.at(1),
      unitConversion * v.at(2)
    );
}
