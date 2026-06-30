#include "WCDPMTSensitiveDetector.hh"

#include "G4Event.hh"
#include "G4RunManager.hh"
#include "G4Step.hh"
#include "G4SystemOfUnits.hh"
#include "G4Track.hh"
#include "WCDResults.hh"

WCDPMTSensitiveDetector::WCDPMTSensitiveDetector(
    const G4String& name, int detectorId, int pmtId, const std::string& model,
    double collectionEfficiency, bool sampleResponseAtPMT)
    : G4VSensitiveDetector(name), detectorId_(detectorId), pmtId_(pmtId),
      sampleResponseAtPMT_(sampleResponseAtPMT), response_(model, collectionEfficiency) {}

G4bool WCDPMTSensitiveDetector::ProcessHits(G4Step* step, G4TouchableHistory*) {
  auto* track = step->GetTrack();
  if (track->GetDefinition()->GetParticleName() != "opticalphoton") return false;
  auto* event = G4RunManager::GetRunManager()->GetCurrentEvent();
  auto* results = static_cast<WCDEventResults*>(event->GetUserInformation());
  if (auto* result = results ? results->Find(detectorId_) : nullptr; result && pmtId_ >= 0 && pmtId_ < 3) {
    ++result->pmtImpacts[pmtId_];
    if (!sampleResponseAtPMT_ || response_.Detect(track->GetTotalEnergy() / eV)) {
      ++result->charge[pmtId_];
    }
  }
  track->SetTrackStatus(fStopAndKill);
  return true;
}
