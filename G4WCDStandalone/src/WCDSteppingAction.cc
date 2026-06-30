#include "WCDSteppingAction.hh"
#include "WCDGeometryView.hh"
#include "WCDResults.hh"
#include "G4RunManager.hh"
#include "G4OpticalPhoton.hh"
#include "G4Step.hh"
#include "G4SystemOfUnits.hh"
#include <algorithm>

void WCDSteppingAction::UserSteppingAction(const G4Step* step) {
  if (step->GetPostStepPoint()->GetPhysicalVolume() == geometry_->SoilVolume()) {
    step->GetTrack()->SetTrackStatus(fStopAndKill);
    return;
  }
  const auto index = [this](const G4VPhysicalVolume* volume) {
    if (!volume) return -1;
    const auto it = std::find(geometry_->WaterVolumes().begin(), geometry_->WaterVolumes().end(), volume->GetLogicalVolume());
    return it == geometry_->WaterVolumes().end() ? -1 : volume->GetCopyNo();
  };
  const int pre = index(step->GetPreStepPoint()->GetPhysicalVolume());
  const int post = index(step->GetPostStepPoint()->GetPhysicalVolume());
  if (pre < 0 && post < 0) return;
  auto* results = static_cast<WCDEventResults*>(G4RunManager::GetRunManager()->GetCurrentEvent()->GetUserInformation());
  if (post >= 0) {
    const int detectorId = geometry_->Tanks().at(post).id;
    if (pre != post || !results->Find(detectorId)) results->Entered(detectorId);
  }
  if (pre >= 0) {
    auto& result = results->Entered(geometry_->Tanks().at(pre).id);
    result.energyDeposit += step->GetTotalEnergyDeposit() / MeV;
    for (const auto* secondary : *step->GetSecondaryInCurrentStep()) {
      const auto* creator = secondary->GetCreatorProcess();
      if (secondary->GetDefinition() == G4OpticalPhoton::OpticalPhotonDefinition() && creator &&
          creator->GetProcessName() == "Cerenkov") {
        ++result.cherenkovPhotons;
      }
    }
  }
}
