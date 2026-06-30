#include "WCDRunAction.hh"

#include "WCDResults.hh"

#include "TFile.h"
#include "TNamed.h"
#include "TTree.h"

#include <algorithm>
#include <stdexcept>
#include <tuple>
#include <utility>

WCDRunAction::WCDRunAction(Settings settings, std::string configuration)
    : settings_(std::move(settings)), configuration_(std::move(configuration)) {}
G4Run* WCDRunAction::GenerateRun() { return new WCDRun; }
void WCDRunAction::EndOfRunAction(const G4Run* run) {
  if (!IsMaster()) return;
  auto values = static_cast<const WCDRun*>(run)->results;
  std::sort(values.begin(), values.end(), [](const Result& a, const Result& b) { return std::tie(a.eventId, a.detectorId) < std::tie(b.eventId, b.detectorId); });
  TFile file(settings_.output.c_str(), "RECREATE");
  if (file.IsZombie()) throw std::runtime_error("Cannot create ROOT output " + settings_.output);
  file.cd();
  TTree tree("Detector", "one entry per entering primary and WCD");
  Result result;
  tree.Branch("partId", &result.partId, "partId/I"); tree.Branch("DetectorId", &result.detectorId, "DetectorId/I");
  tree.Branch("px", &result.px, "px/D"); tree.Branch("py", &result.py, "py/D"); tree.Branch("pz", &result.pz, "pz/D");
  tree.Branch("x", &result.x, "x/D"); tree.Branch("y", &result.y, "y/D"); tree.Branch("z", &result.z, "z/D");
  tree.Branch("energy_deposit", &result.energyDeposit, "energy_deposit/D");
  tree.Branch("cherenkov_photons", &result.cherenkovPhotons, "cherenkov_photons/I");
  tree.Branch("pmt_0_impacts", &result.pmtImpacts[0], "pmt_0_impacts/I"); tree.Branch("pmt_1_impacts", &result.pmtImpacts[1], "pmt_1_impacts/I"); tree.Branch("pmt_2_impacts", &result.pmtImpacts[2], "pmt_2_impacts/I");
  tree.Branch("charge_pmt_0", &result.charge[0], "charge_pmt_0/I"); tree.Branch("charge_pmt_1", &result.charge[1], "charge_pmt_1/I"); tree.Branch("charge_pmt_2", &result.charge[2], "charge_pmt_2/I");
  for (const auto& value : values) { result = value; tree.Fill(); }
  TNamed metadata("Configuration", configuration_.c_str());
  if (metadata.Write() <= 0) throw std::runtime_error("Failed to write ROOT metadata to " + settings_.output);
  if (tree.Write() <= 0) throw std::runtime_error("Failed to write Detector TTree to " + settings_.output);
  file.Close();
  if (file.IsZombie()) throw std::runtime_error("ROOT output became invalid while closing " + settings_.output);
}
