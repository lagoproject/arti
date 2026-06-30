#include "PMTResponse.hh"

#include "Randomize.hh"

#include <algorithm>
#include <stdexcept>

PMTResponse::PMTResponse(std::string model, double collectionEfficiency) : model_(std::move(model)), collectionEfficiency_(collectionEfficiency) {
  if (model_ != "XP1805") throw std::invalid_argument("Unsupported PMT model: " + model_);
  if (collectionEfficiency_ < 0. || collectionEfficiency_ > 1.) throw std::invalid_argument("PMT collection efficiency must be in [0,1]");
}
double PMTResponse::QuantumEfficiency(double nm) const {
  // Match Meiga's active ePMT response (OptDevice::GetQuantumEfficiency).
  if (nm < 250. || nm >= 700.) return 0.;
  if (nm < 300.) return .01;
  if (nm < 350.) return .03;
  if (nm < 400.) return .20;
  if (nm < 450.) return .25;
  if (nm < 500.) return .20;
  if (nm < 550.) return .14;
  if (nm < 600.) return .07;
  if (nm < 650.) return .03;
  return .01;
}
double PMTResponse::DetectionProbability(double energyEV) const {
  if (energyEV <= 0.) return 0.;
  return std::clamp(QuantumEfficiency(1239.841984 / energyEV) * collectionEfficiency_, 0., 1.);
}
bool PMTResponse::Detect(double energyEV) const { return G4UniformRand() < DetectionProbability(energyEV); }
