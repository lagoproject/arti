#pragma once

#include "G4VUserDetectorConstruction.hh"
#include "WCDGeometryView.hh"

#include <memory>
#include <string>
#include <vector>

class WCDMaterials;

class WCDDetectorConstruction final : public G4VUserDetectorConstruction,
                                      public WCDGeometryView {
 public:
  WCDDetectorConstruction(std::vector<Tank> tanks, bool checkOverlaps,
                          std::string pmtModel, double collectionEfficiency, bool fastOpticalMode, double soilSize);
  G4VPhysicalVolume* Construct() override;
  void ConstructSDandField() override;
  const std::vector<G4LogicalVolume*>& WaterVolumes() const override { return waterVolumes_; }
  const std::vector<Tank>& Tanks() const override { return tanks_; }
  const G4VPhysicalVolume* SoilVolume() const override { return soilVolume_; }

 private:
  struct PMTVolume { G4LogicalVolume* volume; int detectorId; int pmtId; };
  std::vector<Tank> tanks_;
  bool checkOverlaps_;
  std::string pmtModel_;
  double collectionEfficiency_;
  bool fastOpticalMode_;
  double soilSize_;
  G4VPhysicalVolume* soilVolume_ = nullptr;
  std::unique_ptr<WCDMaterials> materials_;
  std::vector<G4LogicalVolume*> waterVolumes_;
  std::vector<PMTVolume> pmtVolumes_;
};
