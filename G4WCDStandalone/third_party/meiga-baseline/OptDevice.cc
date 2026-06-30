#include "OptDevice.h"
#include "CLHEP/Random/RandFlat.h"
#include "CLHEP/Random/RandGauss.h"

using namespace std;

OptDevice::OptDevice(int id, OptDevice::DeviceType type) : 
	fOptDeviceId(id) ,
	fType(type)
{ 

	SetProperties(type);
}

OptDevice::OptDevice(OptDevice::DeviceType type) : 
	fType(type)
{ 
	SetProperties(type);
}


void
OptDevice::SetProperties(OptDevice::DeviceType type)
{
	// switch cases for setting device properties

	switch(type) {

		case eSiPM:
			// represented in G4Models as a G4Box
			SetWidth(1.3);
			SetLength(1.3);
			SetThickness(0.1);
			SetName("SiPM");
		break;

		case eMChPMT:
		// represented in G4Models as a G4Box
			SetWidth(1.3);
			SetLength(1.3);
			SetThickness(0.1);
			SetName("Multi-Channel_PMT");
		break;

		case ePMT:
			// represented in G4Models as a G4Ellipsoid
			SetSemiAxisX(10.1);
			SetSemiAxisY(10.1);
			SetSemiAxisZ(6.5);
			SetName("PMT");
		break;

		case eUnknown:
			throw std::invalid_argument( "Unknown Optical Device type!" );
		break;
	}
}

void
OptDevice::SPEPulse(std::vector<double> &amplitude, double fBinTime, std::size_t fStartPulse, const OptDevice::DeviceType &type)
{

	const std::size_t bins = (fPulseDuration/fBinTime);
	
	switch(type) {
		
		case eSiPM:
			// charge-discharge of a capacitor form for SiPM pulse
			for (std::size_t i = 0; i < bins && (fStartPulse + i) < amplitude.size(); ++i) {
				const double t = i*fBinTime;
				amplitude[fStartPulse + i] += fA0 * ( 1.-exp(-(t-fT0) / fTr) * exp(-(t-fT0) / fTf));
			}

		break;

		case eMChPMT:
			// exponentially modified gaussian for MChPMT pulse
			for (std::size_t i = 0; i < bins && (fStartPulse + i) < amplitude.size(); ++i) {
				const double t = i*fBinTime;
				amplitude[fStartPulse + i] += fAmplitude * fLambda * 0.5 * exp(fLambda*0.5 * (2*fMu + fLambda*pow(fSigma, 2) - 2*t)) * erfc((fMu + fLambda*pow(fSigma, 2) -t) / (sqrt(2)*fSigma));
			}

		break;

		case ePMT:
		// need pulse shape for ePMT (large)
			for (std::size_t i = 0; i < bins && (fStartPulse + i) < amplitude.size(); ++i) {
				const double t = i*fBinTime;
				amplitude[fStartPulse + i] += t*0;
			}
		break;		

		case eUnknown:
			throw std::invalid_argument("Unknown Optical Device type!");
		break; 


	} 


}

bool 
OptDevice::IsPhotonDetected(double energy)
{

	/*
	this function returns if "photon" was detected by the SiPM
	based on its photo-detection efficiency
	*/

	double waveLength = 1240. / energy;
	DeviceType t = GetType();
	double qeff = GetQuantumEfficiency(waveLength, t);
	double rand = CLHEP::RandFlat::shoot();

	return (rand < qeff);
	
}


double 
OptDevice::GetQuantumEfficiency(double waveLength, OptDevice::DeviceType type)
{

	double qeff = 0;

	switch (type) 
	{
		case eSiPM:
			{
				if (waveLength >= 300. && waveLength < 350.) 
					qeff = 0.07;
				else if (waveLength >= 350. && waveLength < 400.) 
					qeff = 0.25;
				else if (waveLength >= 400. && waveLength < 450.)
					qeff = 0.37;
				else if (waveLength >= 450. && waveLength < 500.)
					qeff = 0.40;
				else if (waveLength >= 500. && waveLength < 550.)
					qeff = 0.35;
				else if (waveLength >= 550. && waveLength < 600.)
					qeff = 0.29;
				else if (waveLength >= 600. && waveLength < 650.)
					qeff = 0.23;
				else if (waveLength >= 650. && waveLength < 700.)
					qeff = 0.18;
				else if (waveLength >= 700. && waveLength < 750.)
					qeff = 0.13;
				else if (waveLength >= 750. && waveLength < 800.)
					qeff = 0.10;
				else if (waveLength >= 800. && waveLength < 850.)
					qeff = 0.07;
				else if (waveLength >= 850. && waveLength < 900.)
					qeff = 0.04;
			}
			break;

		case eMChPMT:
			{
#warning "Quantum Efficiency has a fixed value for the Multi-Channel PMT!"
				// See QE table for H8804-200 PMT
				if (waveLength >= 300. && waveLength < 650.)
					qeff = 0.25;
			}
			break;

		case ePMT:
			{ 

			if(waveLength >= 250. && waveLength < 300.)
				qeff = 0.01;
			else if(waveLength >= 300. && waveLength < 350.)
				qeff = 0.03;
			else if(waveLength >= 350. && waveLength < 400.)
				qeff = 0.2;
			else if(waveLength >= 400. && waveLength < 450.)
				qeff = 0.25;
			else if(waveLength >= 450. && waveLength < 500.)
				qeff = 0.2;
			else if(waveLength >= 500. && waveLength < 550.)
				qeff = 0.14;
			else if(waveLength >= 550. && waveLength < 600.)
				qeff = 0.07;
			else if(waveLength >= 600. && waveLength < 650.)
				qeff = 0.03;
			else if(waveLength >= 650. && waveLength < 700.)
				qeff = 0.01;

#if 0
				// photonis-XP1805
				if (waveLength >= 250. && waveLength < 270.)
					qeff = 0.03;
				else if (waveLength >= 270. && waveLength < 295.)
					qeff = 0.29;
				else if (waveLength >= 295. && waveLength < 305.)
					qeff = 0.52;
				else if (waveLength >= 305. && waveLength < 315.)
					qeff = 0.74;
				else if (waveLength >= 315. && waveLength < 325.)
					qeff = 0.87;
				else if (waveLength >= 325. && waveLength < 335.)
					qeff = 0.94;
				else if (waveLength >= 335. && waveLength < 345.)
					qeff = 0.97; 
				else if (waveLength >= 345. && waveLength < 355.)
					qeff = 1.00;
				else if (waveLength >= 355. && waveLength < 365.)
					qeff = 1.00;
				else if (waveLength >= 365. && waveLength < 375.)
					qeff = 1.00;
				else if (waveLength >= 375. && waveLength < 385.)
					qeff = 1.00;
				else if (waveLength >= 385. && waveLength < 395.)
					qeff = 1.00;
				else if (waveLength >= 395. && waveLength < 405.)
					qeff = 1.00;
				else if (waveLength >= 405. && waveLength < 415.)
					qeff = 1.00;
				else if (waveLength >= 415. && waveLength < 425.)
					qeff = 0.97;
				else if (waveLength >= 425. && waveLength < 435.)
					qeff = 0.94;
				else if (waveLength >= 435. && waveLength < 445.)
					qeff = 0.90;
				else if (waveLength >= 445. && waveLength < 455.)
					qeff = 0.87;
				else if (waveLength >= 455. && waveLength < 465.)
					qeff = 0.81;
				else if (waveLength >= 465. && waveLength < 475.)
					qeff = 0.77;
				else if (waveLength >= 475. && waveLength < 485.)
					qeff = 0.74;
				else if (waveLength >= 485. && waveLength < 495.)
					qeff = 0.68;
				else if (waveLength >= 495. && waveLength < 505.)
					qeff = 0.64;
				else if (waveLength >= 505. && waveLength < 515.)
					qeff = 0.58;
				else if (waveLength >= 515. && waveLength < 525.)
					qeff = 0.48;
				else if (waveLength >= 525. && waveLength < 535.)
					qeff = 0.41;
				else if (waveLength >= 535. && waveLength < 545.)
					qeff = 0.29;
				else if (waveLength >= 545. && waveLength < 555.)
					qeff = 0.22;
				else if (waveLength >= 555. && waveLength < 565.)
					qeff = 0.19;
				else if (waveLength >= 565. && waveLength < 575.)
					qeff = 0.16;
				else if (waveLength >= 575. && waveLength < 585.)
					qeff = 0.13;

				qeff *= fQEScaleParameter * fPMTCollectionEfficiency;
#endif

				qeff *= fPMTCollectionEfficiency;
			}
			break;
			
			case eUnknown:
				throw std::invalid_argument( "Unknown Optical Device type!" );
			break;

	} // end switch

	return qeff;

}


std::vector<double>
OptDevice::GetOpticalRange()
{

	DeviceType t = GetType();
	switch(t) {
		case eSiPM:
			fOpticalRange = {0., 0.};
		break;

		case eMChPMT:
			fOpticalRange = {0., 0.};
		break;

		case ePMT:
			fOpticalRange = {1.77 ,4.96};
		break;

		case eUnknown:
			throw std::invalid_argument( "Unknown Optical Device type!" );
		break;

	}

	return fOpticalRange;

}


void
OptDevice::SetLogicalVolume(string volName, G4LogicalVolume* log)
{
	fLogicalVolumeMap.emplace(volName, log);
}

bool
OptDevice::HasLogicalVolume(string volName)
{ 
	return fLogicalVolumeMap.find(volName) != fLogicalVolumeMap.end();
}