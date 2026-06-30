#ifndef OptDevice_h
#define OptDevice_h 1

#include "G4LogicalVolume.hh"
#include <vector>
#include <string>

class OptDevice
{
	public:
		enum DeviceType {
			eUnknown,
			eSiPM,
			eMChPMT,
			ePMT
		};

		OptDevice() { }
		OptDevice(int id, OptDevice::DeviceType type);
		OptDevice(OptDevice::DeviceType type);
		virtual ~OptDevice() { }

		void SetProperties(OptDevice::DeviceType type);
		
		// Generic OptDevice stuff
		int GetId() { return fOptDeviceId; }
		void SetId(int id) { fOptDeviceId = id; }

		DeviceType GetType() { return fType; }
		void SetType(OptDevice::DeviceType type) { fType = type; }
		void SetName(std::string name) { fName = name; }
		const std::string GetName() { return fName; }

		// for "squared-shape" optical devices
		// SiPM and Multi-Channel PMT are pixels, i.e., boxes
		double GetLength() { return fOptDeviceLength; }
		void SetLength(double len) { fOptDeviceLength = len; }

		double GetWidth() { return fOptDeviceWidth; }
		void SetWidth(double wid) { fOptDeviceWidth = wid; }

		double GetThickness() { return fOptDeviceThickness; }
		void SetThickness(double thi) { fOptDeviceThickness = thi; }

		// for semi-spherical optical devices (large PMTs)
		double GetSemiAxisX() { return fPMTSemiX; }
		void SetSemiAxisX(double semiX) { fPMTSemiX = semiX; }
		
		double GetSemiAxisY() { return fPMTSemiY; }
		void SetSemiAxisY(double semiY) { fPMTSemiY = semiY; }
		
		double GetSemiAxisZ() { return fPMTSemiZ; }
		void SetSemiAxisZ(double semiZ) { fPMTSemiZ = semiZ; }

		// response stuff
		bool IsPhotonDetected(double energy);
		double GetQuantumEfficiency(double wl, OptDevice::DeviceType t);
		void SPEPulse(std::vector<double> &amplitude, double fBinTime, std::size_t fStartPulse, const OptDevice::DeviceType &type);
		double GetSPEPulseDuration() { return fPulseDuration; }
		std::vector<double> GetOpticalRange();


		// Setters & Getters for Geant4 logical volumes
		void SetLogicalVolume(std::string volName, G4LogicalVolume* log);
		G4LogicalVolume* GetLogicalVolume(std::string volName) { return fLogicalVolumeMap[volName]; }
		bool HasLogicalVolume(std::string volName);

	private:
		int fOptDeviceId;
		DeviceType fType;
		std::string fName; 

		double fOptDeviceLength;
		double fOptDeviceWidth;
		double fOptDeviceThickness;

		// the following variables should be placed in a config file
		// as it is done for the Detector properties

		// SiPM properties
		double fSiPMLength; // 1.3 mm
		double fSiPMWidth; // 1.3 mm
		double fSiPMThickness; // 1.3 mm
		// add quantum efficiency

		// MCh-PMT properties
		double fPMTLength; // 1.3 mm
		double fPMTWidth; // 1.3 mm 
		double fPMTThickness; // 1.3 mm

		// large PMT
		double fPMTSemiX; // 10.1 cm
		double fPMTSemiY; // 10.1 cm
		double fPMTSemiZ; // 6.5 cm

		std::vector<double> fOpticalRange;
		// add quantum efficiency
		double fQEScaleParameter = 0.31;
		// probability of photo-electrons to land on the first dynode (>70%-80%) 
		double fPMTCollectionEfficiency = 0.7;
		
		// SPE pulse parameters
		double fPulseDuration = 100.;

		// sipm SPE pulse parameters
		double fA0 = 0.013; // mV
		double fT0 = -1.160; // ns
		double fTr = 2.679; // ns
		double fTf = 0.329; // ns
		
		// PMT-MCh SPE pulse parameters
		double fAmplitude = 0.024021; // V ns
		double fMu        = 3.312093; // ns
		double fSigma     = 0.265150; 
		double fLambda    = 0.982545; // ns-1


		std::map<std::string, G4LogicalVolume*> fLogicalVolumeMap;
};

#endif