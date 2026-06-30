#include "PMTResponse.hh"
#include "WCDActionInitialization.hh"
#include "WCDConfig.hh"
#include "WCDDetectorConstruction.hh"
#include "WCDPhysicsList.hh"

#include "G4MTRunManager.hh"
#include "G4RunManagerFactory.hh"
#include "G4UImanager.hh"
#include "G4VisExecutive.hh"

#include <filesystem>
#include <algorithm>
#include <limits>
#include <iostream>
#include <memory>
#include <stdexcept>

int main(int argc, char** argv) try {
  const std::filesystem::path config = argc > 1 ? argv[1] : "config/simulation.json";
  const auto configuration = WCDConfig::ReadText(config.string());
  auto settings = WCDConfig::LoadSettings(config.string());
  settings.input = WCDConfig::ResolvePath(config, settings.input);
  const auto detectorFile = WCDConfig::ResolvePath(config, settings.detectors);
  const auto tanks = WCDConfig::LoadTanks(detectorFile);
  auto injection = WCDConfig::LoadInjection(detectorFile);
  if (injection.mode == InjectionMode::eCircle) {
    double sourceZ = -std::numeric_limits<double>::infinity();
    for (const auto& tank : tanks)
      sourceZ = std::max(sourceZ, tank.z - tank.height / 2. + tank.thickness + injection.height);
    injection.height = sourceZ;
  }
  auto inputs = std::make_shared<const std::vector<Primary>>(WCDConfig::LoadPrimaries(settings));
  PMTResponse(settings.pmtModel, settings.collectionEfficiency);

  auto* manager = G4RunManagerFactory::CreateRunManager(G4RunManagerType::MT);
  auto* mtManager = dynamic_cast<G4MTRunManager*>(manager);
  if (!mtManager) throw std::runtime_error("Geant4 was not built with multithreading support");
  mtManager->SetNumberOfThreads(settings.threads);

  auto* geometry = new WCDDetectorConstruction(tanks, settings.overlaps,
                                                settings.pmtModel, settings.collectionEfficiency, settings.simulationMode == "fast", WCDConfig::LoadSoilSize(detectorFile));
  manager->SetUserInitialization(geometry);
  manager->SetUserInitialization(CreateWCDPhysicsList());
  manager->SetUserInitialization(new WCDActionInitialization(
      geometry, inputs, settings, injection, configuration + "\n\n--- detector configuration ---\n" +
      WCDConfig::ReadText(detectorFile)));
  manager->Initialize();

  std::unique_ptr<G4VisExecutive> visManager;
  if (settings.geoVis || settings.trajVis) {
    visManager = std::make_unique<G4VisExecutive>();
    visManager->Initialize();

    auto* uiManager = G4UImanager::GetUIpointer();
    uiManager->ApplyCommand("/vis/open VRML2FILE");
    uiManager->ApplyCommand("/vis/scene/create");
    uiManager->ApplyCommand("/vis/sceneHandler/attach");
    uiManager->ApplyCommand("/vis/scene/add/volume");
    uiManager->ApplyCommand("/vis/scene/add/axes 0 0 0 1 m");
    uiManager->ApplyCommand("/vis/viewer/set/viewpointThetaPhi 0. 0.");
    uiManager->ApplyCommand("/vis/viewer/set/targetPoint 0 0 0");
    uiManager->ApplyCommand("/vis/viewer/set/style wireframe");
    uiManager->ApplyCommand("/vis/scene/notifyHandlers");
    uiManager->ApplyCommand("/vis/viewer/update");
    if (settings.trajVis) {
      uiManager->ApplyCommand("/tracking/storeTrajectory 1");
      uiManager->ApplyCommand("/vis/scene/add/trajectories");
    }
  }
  manager->BeamOn(static_cast<G4int>(inputs->size()));
  delete manager;
  return 0;
} catch (const std::exception& error) {
  std::cerr << "G4WCDSimulator: " << error.what() << '\n';
  return 1;
}
