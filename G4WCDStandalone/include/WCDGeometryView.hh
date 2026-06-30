#pragma once

#include "WCDTypes.hh"

#include <vector>

class G4LogicalVolume;
class G4VPhysicalVolume;

class WCDGeometryView {
 public:
  virtual ~WCDGeometryView() = default;
  virtual const std::vector<G4LogicalVolume*>& WaterVolumes() const = 0;
  virtual const std::vector<Tank>& Tanks() const = 0;
  virtual const G4VPhysicalVolume* SoilVolume() const = 0;
};
