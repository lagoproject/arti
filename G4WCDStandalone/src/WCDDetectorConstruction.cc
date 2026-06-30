#include "WCDDetectorConstruction.hh"

#include "WCDMaterials.hh"
#include "WCDPMTSensitiveDetector.hh"

#include "G4Box.hh"
#include "G4Ellipsoid.hh"
#include "G4LogicalBorderSurface.hh"
#include "G4LogicalVolume.hh"
#include "G4NistManager.hh"
#include "G4OpticalSurface.hh"
#include "G4PVPlacement.hh"
#include "G4SDManager.hh"
#include "G4SystemOfUnits.hh"
#include "G4Tubs.hh"

#include <cmath>
#include <algorithm>
#include <limits>
#include <stdexcept>
#include <utility>

WCDDetectorConstruction::WCDDetectorConstruction(std::vector<Tank> tanks, bool checkOverlaps,
                                                 std::string pmtModel, double collectionEfficiency, bool fastOpticalMode, double soilSize)
    : tanks_(std::move(tanks)), checkOverlaps_(checkOverlaps), pmtModel_(std::move(pmtModel)),
      collectionEfficiency_(collectionEfficiency), fastOpticalMode_(fastOpticalMode), soilSize_(soilSize) {}

G4VPhysicalVolume* WCDDetectorConstruction::Construct() {
  auto* nist = G4NistManager::Instance();
  auto* world = new G4LogicalVolume(new G4Box("World", soilSize_*m, soilSize_*m, soilSize_*m), nist->FindOrBuildMaterial("G4_AIR"), "World");
  auto* root = new G4PVPlacement(nullptr, {}, world, "World", nullptr, false, 0, checkOverlaps_);
  materials_ = std::make_unique<WCDMaterials>();
  if (tanks_.empty()) throw std::runtime_error("Cannot construct soil without WCDs");
  const auto outerBottom = [](const Tank& tank) { return tank.z - tank.height / 2. - tank.thickness; };
  const double soilTop = outerBottom(tanks_.front());
  double minX = std::numeric_limits<double>::infinity(), maxX = -minX;
  double minY = std::numeric_limits<double>::infinity(), maxY = -minY;
  for (const auto& tank : tanks_) {
    if (std::abs(outerBottom(tank) - soilTop) > 1.e-9)
      throw std::runtime_error("All WCDs must share a common base elevation for one soil volume");
    const double outerRadius = tank.radius + tank.thickness;
    minX = std::min(minX, tank.x - outerRadius); maxX = std::max(maxX, tank.x + outerRadius);
    minY = std::min(minY, tank.y - outerRadius); maxY = std::max(maxY, tank.y + outerRadius);
  }
  if (maxX - minX > soilSize_ || maxY - minY > soilSize_)
    throw std::runtime_error("Configured soil size does not cover the WCD array");
  const double soilX = (minX + maxX) / 2., soilY = (minY + maxY) / 2.;
  auto* soil = new G4LogicalVolume(new G4Box("Soil", soilSize_ * m / 2., soilSize_ * m / 2., .05 * m),
                                   nist->FindOrBuildMaterial("G4_CONCRETE"), "Soil");
  soilVolume_ = new G4PVPlacement(nullptr, {soilX * m, soilY * m, (soilTop - .05) * m},
                                  soil, "Soil", world, false, 0, checkOverlaps_);
  for (std::size_t index = 0; index < tanks_.size(); ++index) {
    const auto& tankConfig = tanks_[index];
    if (tankConfig.pmts > 1 && tankConfig.pmtDistance + .101 > tankConfig.radius) throw std::runtime_error("pmtRadialDistance places an XP1805 PMT outside the water volume");
    auto* tank = new G4LogicalVolume(new G4Tubs("TankEnvelope", 0, (tankConfig.radius+tankConfig.thickness)*m, (tankConfig.height/2+tankConfig.thickness)*m, 0, 360*deg), nist->FindOrBuildMaterial("G4_AIR"), "TankEnvelope");
    new G4PVPlacement(nullptr, {tankConfig.x*m, tankConfig.y*m, tankConfig.z*m}, tank, "Tank", world, false, tankConfig.id, checkOverlaps_);
    auto* water = new G4LogicalVolume(new G4Tubs("Water", 0, tankConfig.radius*m, tankConfig.height*m/2, 0, 360*deg), materials_->Water(), "Water");
    auto* waterPV = new G4PVPlacement(nullptr, {}, water, "Water", tank, false, static_cast<int>(index), checkOverlaps_);
    waterVolumes_.push_back(water);
    auto* side = new G4LogicalVolume(new G4Tubs("LinerSide", tankConfig.radius*m, (tankConfig.radius+tankConfig.thickness)*m, tankConfig.height*m/2, 0, 360*deg), materials_->Liner(), "LinerSide");
    auto* sidePV = new G4PVPlacement(nullptr, {}, side, "LinerSide", tank, false, 0, checkOverlaps_);
    auto* cap = new G4LogicalVolume(new G4Tubs("LinerCap", 0, (tankConfig.radius+tankConfig.thickness)*m, tankConfig.thickness*m/2, 0, 360*deg), materials_->Liner(), "LinerCap");
    auto* topPV = new G4PVPlacement(nullptr, {0,0,(tankConfig.height/2+tankConfig.thickness/2)*m}, cap, "LinerTop", tank, false, 0, checkOverlaps_);
    auto* bottomPV = new G4PVPlacement(nullptr, {0,0,-(tankConfig.height/2+tankConfig.thickness/2)*m}, cap, "LinerBottom", tank, false, 1, checkOverlaps_);
    new G4LogicalBorderSurface("WaterToLinerSide", waterPV, sidePV, materials_->LinerSurface());
    new G4LogicalBorderSurface("WaterToLinerTop", waterPV, topPV, materials_->LinerSurface());
    new G4LogicalBorderSurface("WaterToLinerBottom", waterPV, bottomPV, materials_->LinerSurface());
    for (int pmtId = 0; pmtId < tankConfig.pmts; ++pmtId) {
      const double azimuth = tankConfig.pmts == 1 ? 0 : 2*CLHEP::pi*pmtId/tankConfig.pmts;
      const double radius = tankConfig.pmts == 1 ? 0 : tankConfig.pmtDistance;
      auto* cathode = new G4LogicalVolume(new G4Ellipsoid("XP1805", .101*m, .101*m, .065*m, -.065*m, 0), materials_->PMTGlass(), "XP1805");
      new G4PVPlacement(nullptr, {radius*std::cos(azimuth)*m, radius*std::sin(azimuth)*m, tankConfig.height*m/2}, cathode, "XP1805", water, false, pmtId, checkOverlaps_);
      pmtVolumes_.push_back({cathode, tankConfig.id, pmtId});
    }
  }
  return root;
}

void WCDDetectorConstruction::ConstructSDandField() {
  auto* manager = G4SDManager::GetSDMpointer();
  for (const auto& pmt : pmtVolumes_) {
    auto* detector = new WCDPMTSensitiveDetector("WCD_" + std::to_string(pmt.detectorId) + "_PMTSD_" + std::to_string(pmt.pmtId), pmt.detectorId, pmt.pmtId, pmtModel_, collectionEfficiency_, !fastOpticalMode_);
    manager->AddNewDetector(detector);
    pmt.volume->SetSensitiveDetector(detector);
  }
}
