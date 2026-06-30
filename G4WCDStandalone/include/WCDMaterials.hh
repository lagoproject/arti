#pragma once

class G4Material;
class G4OpticalSurface;

// Standalone optical material catalogue. It deliberately owns no detector or
// event state and can safely be shared by Geant4 worker geometry instances.
class WCDMaterials {
 public:
  WCDMaterials();

  G4Material* Water() const { return water_; }
  G4Material* Liner() const { return liner_; }
  G4Material* PMTGlass() const { return pmtGlass_; }
  G4OpticalSurface* LinerSurface() const { return linerSurface_; }

 private:
  G4Material* water_ = nullptr;
  G4Material* liner_ = nullptr;
  G4Material* pmtGlass_ = nullptr;
  G4OpticalSurface* linerSurface_ = nullptr;
};
