#include "WCD.h"
#include "Geometry.h"
#include "G4MDetectorAction.h"
#include "G4MPMTAction.h"
#include "ConfigManager.h"

#include "G4SDManager.hh"
#include "G4VisAttributes.hh"
#include "G4Colour.hh"

#include <iostream>
#include <cmath>
#include <algorithm>
#include <stdexcept>
#include <boost/property_tree/xml_parser.hpp>

using namespace std;
using boost::property_tree::ptree;

G4LogicalVolume *WCD::fLogTank = nullptr;
std::vector<G4LogicalVolume*> WCD::fLogPMTs;
std::ostringstream WCD::fNameDetector;
std::ostringstream WCD::fFullName;

WCD::WCD(const int id, const DetectorType type) :
	Detector(id, type)
{
	fName = "WCD";
	fOverwrittenPropertiesVector.clear();
	SetDefaultProperties();
}

void WCD::BuildDetector(G4LogicalVolume *aLogMother, Event &aEvent, G4bool aCheckOVerlaps)
{
	// solids
	G4Tubs* solidBot  = nullptr;

	// WCD dimensions
	G4double tankRadius = GetTankRadius();
	G4double tankHeight = GetTankHeight();
	G4double tankHalfHeight = 0.5 * fTankHeight;
	G4double tankThickness = GetTankThickness();
	
	// PMT properties photonis-XP1805
	OptDevice pmt = GetOptDevice(OptDevice::ePMT);
	G4double pmtSemiX = pmt.GetSemiAxisX() * CLHEP::cm;
	G4double pmtSemiY = pmt.GetSemiAxisY() * CLHEP::cm;
	G4double pmtSemiZ = pmt.GetSemiAxisZ() * CLHEP::cm;

	G4ThreeVector detectorPos = Geometry::ToG4Vector(GetDetectorPosition(), 1.);
	G4double tankPosX = detectorPos.getX();
	G4double tankPosY = detectorPos.getY();
	G4double tankPosZ = detectorPos.getZ();
	
	// define PMT position as the center of the tank
	G4ThreeVector tankCenter = detectorPos + G4ThreeVector(0, 0, tankHalfHeight + tankThickness);
	int detectorId = GetId();
	int pmtId = 0;
	fNameDetector.str("");
	fNameDetector << "/WCD_"+to_string(detectorId);
	ostringstream msg;
	msg << "Building detector: " << fNameDetector.str() << ", ID: " << detectorId << endl;
	msg << "Tank Radius: " << tankRadius / CLHEP::cm << " cm" << endl;
	msg << "Tank Height: " << tankHeight / CLHEP::cm << " cm" << endl;
	Logger::Print(msg, INFO, "BuildDetector");
	/****************************************************************
		
		Geant4 Volume construction
		
		The Water-Cerenkov Detector (WCD) is a cylindrical tank filled
		of water. The water is contained in a liner bag made of HDPE
		(High Density Polyethylene) and it contains a large 
		photo-multiplier tube at the top of the liner for collecting 
		the Cerenkov photons produced by charged particles in water.
		
		The PMT is simulated as a semi-sphere made of Pyrex
		to account for reflectivity of photons at the PMT
		window. The PMT volume is registered as a SensitiveDetector
		and its response is computed by the G4MPMTAction class.

	****************************************************************/
	// Tank
	G4Tubs* solidTank = new G4Tubs("Tank", 0, tankRadius, tankHalfHeight, 0, 360*deg);
	G4Tubs* solidTop = new G4Tubs("Top", 0, tankRadius + tankThickness, tankThickness/2, 0, 360*deg);
	G4Tubs* solidSide = new G4Tubs("Side", tankRadius, tankRadius + tankThickness, tankHalfHeight, 0, 360*deg);

	// water part
	fLogTank  = new G4LogicalVolume(solidTank, Materials().Water, "logTank", 0, 0, 0);
	G4PVPlacement* physTank = new G4PVPlacement(nullptr, tankCenter, fLogTank, "physTank", aLogMother, false, 0, aCheckOVerlaps);
	// register water logical volume in the Detector
	if (!HasLogicalVolume("logTank"))
		SetLogicalVolume("logTank", fLogTank);
	
	// top, bottom and side walls of the tank
	G4LogicalVolume* logTop  = new G4LogicalVolume(solidTop, Materials().HDPE, "logTop", 0, 0, 0);
	G4PVPlacement* physTop = new G4PVPlacement(nullptr, 
												G4ThreeVector(tankPosX, tankPosY, tankPosZ + 2*tankHalfHeight + 1.5*tankThickness), 
												logTop, "physTop", aLogMother, 
												false, 0, aCheckOVerlaps);
	// solidBot = nullptr??
	G4LogicalVolume* logBot = new G4LogicalVolume(solidBot, Materials().HDPE, "logBot", 0, 0, 0);
	G4PVPlacement* physBot = new G4PVPlacement(nullptr, 
												G4ThreeVector(tankPosX, tankPosY, tankPosZ + 0.5*tankThickness), 
												logTop, "physBot", aLogMother, 
												false, 0, aCheckOVerlaps);
	
	G4LogicalVolume* logSide  = new G4LogicalVolume(solidSide, Materials().HDPE, "logSide", 0, 0, 0);
	G4PVPlacement* physSide = new G4PVPlacement(nullptr, 
												G4ThreeVector(tankPosX, tankPosY, tankPosZ + tankHalfHeight + tankThickness), logSide, "physSide", aLogMother, 
												false, 0, aCheckOVerlaps);

	// tank liner surface
	new G4LogicalBorderSurface("TopSurface", physTank, physTop, Materials().LinerOptSurf);
	new G4LogicalBorderSurface("BotSurface", physTank, physBot, Materials().LinerOptSurf);
	new G4LogicalBorderSurface("SideSurface", physTank, physSide, Materials().LinerOptSurf);

	auto sdMan = G4SDManager::GetSDMpointer();
	fLogPMTs.clear();
	for (int pmtId = 0; pmtId < GetNumberOfPMTs(); ++pmtId) {
		G4double azimuth = 0.;
		if (GetNumberOfPMTs() == 2) {
			azimuth = pmtId * 180. * deg;
		} else if (GetNumberOfPMTs() == 3) {
			azimuth = pmtId * 120. * deg;
		}

		G4double pmtRadialDistance = GetPMTRadialDistance();
	if (GetNumberOfPMTs() > 1) {
		if (pmtRadialDistance < 0.) {
			pmtRadialDistance = 0.5 * tankRadius;
		}
		G4double pmtRadialExtent = std::max(pmtSemiX, pmtSemiY);
		if (pmtRadialDistance + pmtRadialExtent > tankRadius) {
			throw std::invalid_argument("pmtRadialDistance places a PMT outside the tank");
		}
	}

	G4ThreeVector pmtPosition(0., 0., tankHalfHeight);
		if (GetNumberOfPMTs() > 1) {
			pmtPosition.setX(pmtRadialDistance * std::cos(azimuth));
			pmtPosition.setY(pmtRadialDistance * std::sin(azimuth));
		}

		string pmtSuffix = "_" + to_string(pmtId);
		G4Ellipsoid* solidPMT = new G4Ellipsoid("PMT" + pmtSuffix, pmtSemiX, pmtSemiY, pmtSemiZ, -pmtSemiZ, 0);
		G4LogicalVolume* logPMT = new G4LogicalVolume(solidPMT, Materials().Pyrex, "logPMT" + pmtSuffix, 0, 0, 0);
		new G4PVPlacement(nullptr, pmtPosition, logPMT, "physPMT" + pmtSuffix, fLogTank, false, pmtId, aCheckOVerlaps);
		fLogPMTs.push_back(logPMT);

		if (!HasOptDevice(pmtId)) {
			MakeOptDevice(pmtId, OptDevice::ePMT);
			cout << "[INFO] Adding PMT id = " << pmtId << endl;
		}
		string optName = pmt.GetName() + pmtSuffix;
		fFullName.str("");
		fFullName << "/WCD_" + to_string(detectorId) << "/" << optName;

		G4MPMTAction* const pmtSD = new G4MPMTAction(fFullName.str().c_str(), detectorId, pmtId, aEvent);
		sdMan->AddNewDetector(pmtSD);
		logPMT->SetSensitiveDetector(pmtSD);
	}

	// register water volume as sensitive detector
	G4MDetectorAction* const waterSD = new G4MDetectorAction(fNameDetector.str().c_str(), detectorId, aEvent);
	sdMan->AddNewDetector(waterSD);
	fLogTank->SetSensitiveDetector(waterSD);
	
}

void WCD::ConstructSensitiveDetector(Detector &aDetector, Event &aEvent)
{

	auto sdMan = G4SDManager::GetSDMpointer();
	for (int pmtId = 0; pmtId < static_cast<int>(fLogPMTs.size()); ++pmtId) {
		std::ostringstream fullName;
		fullName << "/WCD_" << aDetector.GetId() << "/"
			 << aDetector.GetOptDevice(pmtId).GetName() << "_" << pmtId;
		G4MPMTAction* const pmtSD = new G4MPMTAction(fullName.str().c_str(), aDetector.GetId(), pmtId, aEvent);
		sdMan->AddNewDetector(pmtSD);
		fLogPMTs[pmtId]->SetSensitiveDetector(pmtSD);
	}
	// register water volume as sensitive detector
	G4MDetectorAction* const waterSD = new G4MDetectorAction(fNameDetector.str().c_str(), aDetector.GetId(), aEvent);
	sdMan->AddNewDetector(waterSD);
	if(fLogTank != nullptr) {
		fLogTank->SetSensitiveDetector(waterSD);
	}

}

void WCD::SetDefaultProperties()
{
	SetNumberOfPMTs(1);
	SetPMTRadialDistance(-1.);
	if (fDefaultPropertiesFile.empty()) 
		return;
	
	Logger::Print("Setting default properties from file "+fDefaultPropertiesFile, INFO, "SetDefaultProperties");
	ptree tree;
	read_xml(fDefaultPropertiesFile, tree);
	string branchName = "detectorProperties";

	SetTankRadius( ConfigManager::GetPropertyFromXML<double>(tree, branchName, "tankRadius") );
	SetTankHeight( ConfigManager::GetPropertyFromXML<double>(tree, branchName, "tankHeight") );
	SetTankThickness( ConfigManager::GetPropertyFromXML<double>(tree, branchName, "tankThickness") );
	SetImpuritiesFraction( ConfigManager::GetPropertyFromXML<double>(tree, branchName, "impuritiesFraction", false) );
}

void WCD::SetDetectorProperties(const boost::property_tree::ptree &aTree)
{
	vector<double> detPosition;
	detPosition.reserve(3);

	for (const auto& property : aTree) {
		string xmlLabel = property.first;
		string xmlValue = property.second.data();

		if(xmlLabel == "<xmlattr>")
			continue;
		if(xmlLabel == "<xmlcomment>")
			continue;

		if ( xmlLabel == "x" || xmlLabel == "y" || xmlLabel == "z") {
			string value = property.second.data();
			boost::algorithm::trim(value);
			double dValue = stod(value);
			string unit = property.second.get<string>("<xmlattr>.unit");
			double coord = G4UnitDefinition::GetValueOf(unit) * dValue;
			detPosition.push_back(coord);
		} else if (xmlLabel == "tankRadius") {
				double value = stod(xmlValue);
				double unit = G4UnitDefinition::GetValueOf(property.second.get<string>("<xmlattr>.unit"));
				fOverwrittenPropertiesVector.push_back(xmlLabel);
				SetTankRadius(value * unit);
			}
			else if (xmlLabel == "tankHeight") {
				double value = stod(xmlValue);
				double unit = G4UnitDefinition::GetValueOf(property.second.get<string>("<xmlattr>.unit"));
				fOverwrittenPropertiesVector.push_back(xmlLabel);
				SetTankHeight(value * unit);
			}
			else if (xmlLabel == "tankThickness") {
				double value = stod(xmlValue);
				double unit = G4UnitDefinition::GetValueOf(property.second.get<string>("<xmlattr>.unit"));
				fOverwrittenPropertiesVector.push_back(xmlLabel);
				SetTankThickness(value * unit);
			}
			else if (xmlLabel == "impuritiesFraction") {
				double value = stod(xmlValue);
				fOverwrittenPropertiesVector.push_back(xmlLabel);
				SetImpuritiesFraction(value);
			}
			else if (xmlLabel == "numberOfPMTs") {
				string value = xmlValue;
				boost::algorithm::trim(value);
				size_t parsed = 0;
				int numberOfPMTs;
				try {
					numberOfPMTs = stoi(value, &parsed);
				} catch (const std::exception&) {
					throw std::invalid_argument("numberOfPMTs must be one of: 1, 2, 3");
				}
				if (parsed != value.size() || numberOfPMTs < 1 || numberOfPMTs > 3) {
					throw std::invalid_argument("numberOfPMTs must be one of: 1, 2, 3");
				}
				fOverwrittenPropertiesVector.push_back(xmlLabel);
				SetNumberOfPMTs(numberOfPMTs);
			}
			else if (xmlLabel == "pmtRadialDistance") {
				double value = stod(xmlValue);
				double unit = G4UnitDefinition::GetValueOf(property.second.get<string>("<xmlattr>.unit"));
				if (value <= 0.) {
					throw std::invalid_argument("pmtRadialDistance must be greater than zero");
				}
				fOverwrittenPropertiesVector.push_back(xmlLabel);
				SetPMTRadialDistance(value * unit);
			}
			else {
				ostringstream msg;
				msg << xmlLabel << " is not a property of detector " << TypeToString(fType) << ". Skipping...";
				Logger::Print(msg, WARNING, "SetDetectorProperties");
		}
	}
	SetDetectorPosition(detPosition);
	Logger::PrintVector(fDetectorPosition, "Detector position: ", INFO, "SetDetectorProperties");
	
	if(!fOverwrittenPropertiesVector.empty()) {
		Logger::PrintVector(fOverwrittenPropertiesVector, "Overwritten properties for detector " + TypeToString(fType), INFO, "SetDetectorProperties");
	}
}
