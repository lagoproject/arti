#ifndef WCD_h
#define WCD_h 1

// Meiga classes
//#include "Event.h"
#include "Detector.h"
#include "Materials.h"

// geant4 classes
// #include "G4SDManager.hh"
#include "G4PVPlacement.hh"
#include "G4LogicalVolume.hh"
#include "G4LogicalBorderSurface.hh"
#include "G4Box.hh"
#include "G4Tubs.hh"
#include "G4Sphere.hh"
#include "G4Ellipsoid.hh"

#include <vector>

class G4VPhysicalVolume;
class G4LogicalVolume;
class G4OpticalSkinSurface;
class Event;

class WCD : public Detector 
{
	// Basic Geant4 model for a Water-Cerenkov Detector
	friend class SaltyWCD;

public:
	WCD(const int id, const DetectorType type);
	virtual void BuildDetector(G4LogicalVolume *logMother, Event &aEvent, G4bool overlaps = false) override;
	static void ConstructSensitiveDetector(Detector &aDetector, Event &aEvent);

private:
	virtual void SetDefaultProperties() override;
	virtual void SetDetectorProperties(const boost::property_tree::ptree &aTree) override;
	
	double GetTankHeight() const { return fTankHeight; }
	void SetTankHeight(double h) { fTankHeight = h; }
	
	double GetTankRadius() const { return fTankRadius; }
	void SetTankRadius(double r) { fTankRadius = r; }

	double GetTankThickness() const { return fTankThickness; }
	void SetTankThickness(double t) { fTankThickness = t; }

	double GetImpuritiesFraction() const { return fImpuritiesFraction; }
	void SetImpuritiesFraction(double impF) { fImpuritiesFraction = impF; }

	int GetNumberOfPMTs() const { return fNumberOfPMTs; }
	void SetNumberOfPMTs(int numberOfPMTs) { fNumberOfPMTs = numberOfPMTs; }

	double GetPMTRadialDistance() const { return fPMTRadialDistance; }
	void SetPMTRadialDistance(double radialDistance) { fPMTRadialDistance = radialDistance; }

private:
	static std::ostringstream fNameDetector;
	static std::ostringstream fFullName;
	static G4LogicalVolume* fLogTank;
	static std::vector<G4LogicalVolume*> fLogPMTs;

	double fTankHeight;
	double fTankRadius;
	double fTankThickness;
	double fImpuritiesFraction;
	int fNumberOfPMTs;
	double fPMTRadialDistance;

};

#endif