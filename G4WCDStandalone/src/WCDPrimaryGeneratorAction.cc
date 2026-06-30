#include "WCDPrimaryGeneratorAction.hh"

#include "G4Event.hh"
#include "G4ParticleGun.hh"
#include "G4ParticleDefinition.hh"
#include "G4ParticleTable.hh"
#include "G4PhysicalConstants.hh"
#include "G4SystemOfUnits.hh"
#include "Randomize.hh"
#include "WCDResults.hh"

#include <algorithm>
#include <cmath>
#include <stdexcept>

WCDPrimaryGeneratorAction::WCDPrimaryGeneratorAction(std::shared_ptr<const std::vector<Primary>> inputs, Injection injection, long baseSeed) : inputs_(std::move(inputs)), injection_(injection), baseSeed_(baseSeed), gun_(new G4ParticleGun(1)) {}
WCDPrimaryGeneratorAction::~WCDPrimaryGeneratorAction() { delete gun_; }
void WCDPrimaryGeneratorAction::GeneratePrimaries(G4Event* event) {
  const auto& input=inputs_->at(event->GetEventID());
  CLHEP::HepRandom::setTheSeed(baseSeed_+long(0x9e3779b9ULL*unsigned(event->GetEventID())));
  auto* particle=G4ParticleTable::GetParticleTable()->FindParticle(input.pdg);
  if(!particle)throw std::runtime_error("Unknown PDG id "+std::to_string(input.pdg));
  auto x = input.x, y = input.y, z = input.z;
  const auto radians = [](double degrees) { return degrees * CLHEP::pi / 180.; };
  switch (injection_.mode) {
    case InjectionMode::eCircle: {
      const auto radius = injection_.radius * std::sqrt(G4UniformRand());
      const auto phi = radians(injection_.minPhi + (injection_.maxPhi - injection_.minPhi) * G4UniformRand());
      x = injection_.x + radius * std::cos(phi);
      y = injection_.y + radius * std::sin(phi);
      z = injection_.height;
      break;
    }
    case InjectionMode::eHalfSphere: {
      const auto minTheta = radians(injection_.minTheta), maxTheta = radians(injection_.maxTheta);
      const auto theta = std::acos(std::cos(maxTheta) + (std::cos(minTheta) - std::cos(maxTheta)) * G4UniformRand());
      const auto phi = radians(injection_.minPhi + (injection_.maxPhi - injection_.minPhi) * G4UniformRand());
      x = injection_.x + injection_.radius * std::sin(theta) * std::cos(phi);
      y = injection_.y + injection_.radius * std::sin(theta) * std::sin(phi);
      z = injection_.z + injection_.radius * std::cos(theta);
      break;
    }
    case InjectionMode::eVertical: {
      z = std::max(injection_.z, injection_.height);
      if (injection_.radius > 0) {
        const auto radius = injection_.radius * std::sqrt(G4UniformRand());
        const auto phi = radians(injection_.minPhi + (injection_.maxPhi - injection_.minPhi) * G4UniformRand());
        x = injection_.x + radius * std::cos(phi);
        y = injection_.y + radius * std::sin(phi);
      } else { x = injection_.x; y = injection_.y; }
      break;
    }
    case InjectionMode::eFromFile: break;
  }
  const G4ParticleMomentum momentum(input.px * GeV, input.py * GeV, input.pz * GeV);
  if (momentum.mag2() <= 0.) throw std::runtime_error("Primary momentum must be non-zero");
  const auto mass = particle->GetPDGMass();
  const auto kineticEnergy = std::sqrt(momentum.mag2() + mass * mass) - mass;
  gun_->SetParticleDefinition(particle);
  gun_->SetParticlePosition({x*m,y*m,z*m});
  gun_->SetParticleMomentumDirection(momentum);
  gun_->SetParticleEnergy(kineticEnergy);
  Result result;result.eventId=event->GetEventID();result.partId=input.pdg;result.px=input.px;result.py=input.py;result.pz=input.pz;result.x=x;result.y=y;result.z=z;
  event->SetUserInformation(new WCDEventResults(result));gun_->GeneratePrimaryVertex(event);
}
