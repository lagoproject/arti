#pragma once

#include <array>
#include <string>

struct Primary {
  int pdg = 13;
  double px = 0, py = 0, pz = -1;
  double x = 0, y = 0, z = 3;
};

struct Tank {
  int id = 0, pmts = 3;
  double radius = 1.8, height = 1.2, thickness = .02;
  double x = 0, y = 0, z = 0, pmtDistance = .9;
};

enum class InjectionMode { eCircle, eHalfSphere, eVertical, eFromFile };

struct Injection {
  InjectionMode mode = InjectionMode::eFromFile;
  double x = 0, y = 0, z = 0;
  double radius = 0, height = 0;
  double minTheta = 0, maxTheta = 90;
  double minPhi = 0, maxPhi = 360;
};

struct Settings {
  int threads = 2;
  long seed = 123456789;
  bool overlaps = false, geoVis = false, trajVis = false;
  double collectionEfficiency = .70;
  std::string pmtModel = "XP1805", inputMode = "arti", simulationMode = "full";
  std::string input = "input.shw", output = "Detector.root", detectors = "detector.xml";
};

struct Result {
  int eventId = -1, partId = 0, detectorId = -1;
  double px = 0, py = 0, pz = 0, x = 0, y = 0, z = 0, energyDeposit = 0;
  std::array<int, 3> charge{{0, 0, 0}};
  int cherenkovPhotons = 0;
  std::array<int, 3> pmtImpacts{{0, 0, 0}};
  bool enteredWater = false;
};
