#pragma once

#include <string>

// Wavelength-dependent response for the large WCD PMT. The table and default
// 0.70 collection efficiency are extracted from Meiga's OptDevice baseline.
class PMTResponse {
 public:
  explicit PMTResponse(std::string model = "XP1805", double collectionEfficiency = 0.70);

  double QuantumEfficiency(double wavelengthNm) const;
  double DetectionProbability(double photonEnergyEV) const;
  bool Detect(double photonEnergyEV) const;

 private:
  std::string model_;
  double collectionEfficiency_;
};
