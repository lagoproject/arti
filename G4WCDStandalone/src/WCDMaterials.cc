#include "WCDMaterials.hh"

#include "G4Element.hh"
#include "G4Material.hh"
#include "G4MaterialPropertiesTable.hh"
#include "G4NistManager.hh"
#include "G4OpticalSurface.hh"
#include "G4SystemOfUnits.hh"

#include <array>

WCDMaterials::WCDMaterials() {
  auto* nist = G4NistManager::Instance();
  auto* hydrogen = nist->FindOrBuildElement("H");
  auto* oxygen = nist->FindOrBuildElement("O");
  auto* carbon = nist->FindOrBuildElement("C");
  auto* silicon = nist->FindOrBuildElement("Si");
  auto* boron = nist->FindOrBuildElement("B");
  auto* sodium = nist->FindOrBuildElement("Na");

  water_ = new G4Material("WCDWater", 1.0 * g / cm3, 2);
  water_->AddElement(hydrogen, 2);
  water_->AddElement(oxygen, 1);
  std::array<G4double, 30> energy = {
      2.08*eV,2.16*eV,2.19*eV,2.23*eV,2.27*eV,2.32*eV,2.36*eV,2.41*eV,2.46*eV,2.50*eV,
      2.56*eV,2.61*eV,2.67*eV,2.72*eV,2.79*eV,2.85*eV,2.92*eV,2.99*eV,3.06*eV,3.14*eV,
      3.22*eV,3.31*eV,3.40*eV,3.49*eV,3.59*eV,3.70*eV,3.81*eV,3.94*eV,4.07*eV,4.20*eV};
  std::array<G4double, 30> absorption = {
      9.2*m,13.3*m,18.0*m,20.3*m,22.6*m,25.8*m,28.4*m,30.2*m,40.3*m,56.0*m,
      73.5*m,81.8*m,92.3*m,92.3*m,99.3*m,99.3*m,100*m,94.1*m,88.9*m,84.2*m,
      75.4*m,65.5*m,48.0*m,38.0*m,31.1*m,25.7*m,21.2*m,17.1*m,13.7*m,10.2*m};
  G4double waterEnergy[] = {2.08*eV, 4.20*eV};
  G4double waterIndex[] = {1.33, 1.33};
  auto* waterProperties = new G4MaterialPropertiesTable;
  waterProperties->AddProperty("RINDEX", waterEnergy, waterIndex, 2);
  waterProperties->AddProperty("ABSLENGTH", energy.data(), absorption.data(), energy.size());
  water_->SetMaterialPropertiesTable(waterProperties);

  liner_ = new G4Material("WCDHDPE", .94*g/cm3, 2);
  liner_->AddElement(carbon, 2);
  liner_->AddElement(hydrogen, 4);
  auto* silica = new G4Material("WCDSiO2", 2.65*g/cm3, 2); silica->AddElement(silicon, 1); silica->AddElement(oxygen, 2);
  auto* boronOxide = new G4Material("WCDB2O2", 2.23*g/cm3, 2); boronOxide->AddElement(boron, 2); boronOxide->AddElement(oxygen, 2);
  auto* sodiumOxide = new G4Material("WCDNa2O", 2.23*g/cm3, 2); sodiumOxide->AddElement(sodium, 2); sodiumOxide->AddElement(oxygen, 1);
  pmtGlass_ = new G4Material("WCDPyrex", 2.23*g/cm3, 3);
  pmtGlass_->AddMaterial(silica, .80); pmtGlass_->AddMaterial(boronOxide, .13); pmtGlass_->AddMaterial(sodiumOxide, .07);
  G4double glassEnergy[] = {2.00*eV, 4.00*eV};
  G4double glassIndex[] = {1.47, 1.47};
  G4double glassAbsorption[] = {.0005*mm, .0005*mm};
  auto* glassProperties = new G4MaterialPropertiesTable;
  glassProperties->AddProperty("RINDEX", glassEnergy, glassIndex, 2);
  glassProperties->AddProperty("ABSLENGTH", glassEnergy, glassAbsorption, 2);
  pmtGlass_->SetMaterialPropertiesTable(glassProperties);

  std::array<G4double,30> reflectivity = { .936,.935,.935,.934,.934,.934,.934,.934,.935,.936,.937,.938,.939,.939,.940,.940,.939,.938,.935,.931,.925,.917,.906,.893,.877,.856,.832,.803,.769,.729 };
  std::array<G4double,30> zero{};
  G4double lobeEnergy[] = {2.08*eV,3.00*eV,4.20*eV}; G4double lobe[] = {.2,.2,.2}; G4double spike[] = {0,0,0};
  auto* surfaceProperties = new G4MaterialPropertiesTable;
  surfaceProperties->AddProperty("REFLECTIVITY", energy.data(), reflectivity.data(), energy.size());
  surfaceProperties->AddProperty("SPECULARLOBECONSTANT", lobeEnergy,lobe,3);
  surfaceProperties->AddProperty("SPECULARSPIKECONSTANT", lobeEnergy,spike,3);
  surfaceProperties->AddProperty("BACKSCATTERCONSTANT", energy.data(),zero.data(),zero.size());
  linerSurface_ = new G4OpticalSurface("WCDTyvekSurface", unified, ground, dielectric_metal, .17);
  linerSurface_->SetMaterialPropertiesTable(surfaceProperties);
}
