#include "WCDConfig.hh"

#include <fstream>
#include <regex>
#include <sstream>
#include <stdexcept>
#include <unordered_map>
#include <unordered_set>

namespace {
std::string field(const std::string& text, const std::string& name) { std::smatch match; const std::regex expression("\\\""+name+"\\\"\\s*:\\s*(?:\\\"([^\\\"]*)\\\"|([^,}[:space:]]+))"); return std::regex_search(text,match,expression)?(match[1].matched?match[1].str():match[2].str()):""; }
std::string object(const std::string& text, const std::string& name) { std::smatch match; return std::regex_search(text, match, std::regex("\\\"" + name + "\\\"\\s*:\\s*\\{([^}]*)\\}")) ? match[1].str() : ""; }
double attribute(const std::string& text,const std::string& name,double fallback=0) { std::smatch match; return std::regex_search(text,match,std::regex(name+"=\\\"([^\\\"]+)\\\""))?std::stod(match[1]):fallback; }
std::string textAttribute(const std::string& text, const std::string& name) { std::smatch match; return std::regex_search(text, match, std::regex(name + "=\"([^\"]+)\"")) ? match[1].str() : ""; }
double lengthAttribute(const std::string& text, const std::string& name, double fallback) { const auto value = attribute(text, name, fallback); const auto unit = textAttribute(text, "unit"); if (unit.empty() || unit == "m") return value; if (unit == "cm") return value / 100.; if (unit == "mm") return value / 1000.; throw std::runtime_error("Unsupported length unit: " + unit); }
int corsikaToPdg(int id) { static const std::unordered_map<int,int> map={{1,22},{2,-11},{3,11},{5,-13},{6,13},{7,111},{8,211},{9,-211},{10,130},{11,321},{12,-321},{13,2112},{14,2212},{15,-2212},{16,310},{17,221},{18,3122},{19,3222},{20,3212},{21,3112},{22,3322},{23,3312},{24,3332},{25,-2112},{26,-3122},{27,-3222},{28,-3212},{29,-3112},{30,-3322},{31,-3312},{32,-3332},{49,333},{50,223},{51,113},{52,213},{53,-213},{54,2224},{55,2214},{56,2114},{57,1114},{58,-2224},{59,-2214},{60,-2114},{61,-1114},{62,313},{63,323},{64,-323},{66,12},{67,-12},{68,14},{69,-14}}; if(id>=100&&id<9900){const int z=id%100,a=id/100;return 1000000000+z*10000+a*10;} const auto found=map.find(id); return found==map.end()?0:found->second; }
}
namespace WCDConfig {
std::string ReadText(const std::string& path) { std::ifstream input(path); if(!input)throw std::runtime_error("Cannot read "+path); return {std::istreambuf_iterator<char>(input),{}}; }
Settings LoadSettings(const std::string& path) { Settings settings;const auto text=ReadText(path);const auto input=object(text,"Input"), simulation=object(text,"Simulation"), output=object(text,"Output"), pmt=object(text,"PMT");if(auto v=field(simulation,"Threads");!v.empty())settings.threads=std::stoi(v);if(auto v=field(simulation,"BaseSeed");!v.empty())settings.seed=std::stol(v);if(auto v=field(simulation,"CheckOverlaps");!v.empty())settings.overlaps=v=="true";if(auto v=field(simulation,"GeoVisOn");!v.empty())settings.geoVis=v=="true";if(auto v=field(simulation,"TrajVisOn");!v.empty())settings.trajVis=v=="true";if(auto v=field(simulation,"Mode");!v.empty())settings.simulationMode=v;if(auto v=field(input,"Mode");!v.empty())settings.inputMode=v;if(auto v=field(input,"File");!v.empty())settings.input=v;if(auto v=field(output,"RootFile");!v.empty())settings.output=v;if(auto v=field(text,"DetectorList");!v.empty())settings.detectors=v;if(auto v=field(pmt,"CollectionEfficiency");!v.empty())settings.collectionEfficiency=std::stod(v);if(auto v=field(pmt,"Model");!v.empty())settings.pmtModel=v;if(settings.threads<1)throw std::runtime_error("Simulation.Threads must be positive");if(settings.collectionEfficiency<0||settings.collectionEfficiency>1)throw std::runtime_error("PMT.CollectionEfficiency must be in [0,1]");if(settings.simulationMode!="full"&&settings.simulationMode!="fast")throw std::runtime_error("Simulation.Mode must be full or fast");return settings; }
double LoadSoilSize(const std::string& path) { const auto text = ReadText(path); std::smatch match; if (!std::regex_search(text, match, std::regex("<soil\\b[^>]*/>"))) return 5.; const double size = lengthAttribute(match.str(), "size", 5.); if (size <= 0.) throw std::runtime_error("soil size must be positive"); return size; }
std::vector<Tank> LoadTanks(const std::string& path) { const auto text=ReadText(path);std::vector<Tank> output;std::unordered_set<int> ids;const std::regex detectors("<detector\\b[^>]*>[\\s\\S]*?</detector>");for(std::sregex_iterator it(text.begin(),text.end(),detectors),end;it!=end;++it){const std::string block=it->str();Tank tank;tank.id=int(attribute(block,"id"));std::smatch match;if(std::regex_search(block,match,std::regex("<position[^>]*>"))){const auto value=match.str();tank.x=attribute(value,"x");tank.y=attribute(value,"y");tank.z=attribute(value,"z");}if(std::regex_search(block,match,std::regex("<tank[^>]*/>"))){const auto value=match.str();tank.radius=attribute(value,"radius");tank.height=attribute(value,"height");tank.thickness=attribute(value,"thickness");}if(std::regex_search(block,match,std::regex("<numberOfPMTs>([0-9]+)</numberOfPMTs>")))tank.pmts=std::stoi(match[1]);if(std::regex_search(block,match,std::regex("<pmtRadialDistance[^>]*>([^<]+)</pmtRadialDistance>")))tank.pmtDistance=std::stod(match[1]);if(!ids.insert(tank.id).second||tank.radius<=0||tank.height<=0||tank.thickness<=0||tank.pmts<1||tank.pmts>3||(tank.pmts>1&&tank.pmtDistance<=0))throw std::runtime_error("Invalid WCD definition in "+path);output.push_back(tank);}if(output.empty())throw std::runtime_error("No detector definitions in "+path);return output; }
Injection LoadInjection(const std::string& path) {
  const auto text = ReadText(path);
  std::smatch injectionMatch;
  if (!std::regex_search(text, injectionMatch, std::regex(R"rx(<injectionMode([^>]*)>([[:space:][:graph:]]*)</injectionMode>)rx")) && !std::regex_search(text, injectionMatch, std::regex(R"rx(<injectionMode([^>]*)/>)rx"))) return {};
  const auto attributes = injectionMatch[1].str();
  std::smatch typeMatch;
  if (!std::regex_search(attributes, typeMatch, std::regex(R"rx(type="([^"]+)")rx")))
    throw std::runtime_error("injectionMode requires a type attribute");
  Injection injection;
  const auto type = typeMatch[1].str();
  if (type == "eCircle") injection.mode = InjectionMode::eCircle;
  else if (type == "eHalfSphere") injection.mode = InjectionMode::eHalfSphere;
  else if (type == "eVertical") injection.mode = InjectionMode::eVertical;
  else if (type == "eFromFile") injection.mode = InjectionMode::eFromFile;
  else throw std::runtime_error("Unsupported injection mode: " + type);
  const auto value = [&injectionMatch](const std::string& name, double fallback) {
    std::smatch match;
    const auto contents = injectionMatch[2].str();
    if (!std::regex_search(contents, match, std::regex("<" + name + "([[:space:]][^>]*)?>[[:space:]]*([^<]+)[[:space:]]*</" + name + ">"))) return fallback;
    const double number = std::stod(match[2].str());
    const auto unitAttributes = match[1].str();
    std::smatch unit;
    if (!std::regex_search(unitAttributes, unit, std::regex(R"rx(unit="([^"]+)")rx"))) return number;
    if (unit[1] == "m") return number;
    if (unit[1] == "cm") return number / 100.;
    if (unit[1] == "mm") return number / 1000.;
    throw std::runtime_error("Unsupported injection length unit: " + unit[1].str());
  };
  injection.x = value("x", injection.x);
  injection.y = value("y", injection.y);
  injection.z = value("z", injection.z);
  injection.radius = value("radius", injection.radius);
  injection.height = value("height", injection.height);
  injection.minTheta = value("minTheta", injection.minTheta);
  injection.maxTheta = value("maxTheta", injection.maxTheta);
  injection.minPhi = value("minPhi", injection.minPhi);
  injection.maxPhi = value("maxPhi", injection.maxPhi);
  if (injection.radius < 0 || injection.minTheta > injection.maxTheta || injection.minPhi > injection.maxPhi)
    throw std::runtime_error("Invalid injectionMode bounds");
  return injection;
}
std::vector<Primary> LoadPrimaries(const Settings& settings) { std::ifstream input(settings.input);if(!input)throw std::runtime_error("Cannot read input particle file "+settings.input);std::vector<Primary> output;unsigned lineNumber=0;for(std::string line;std::getline(input,line);){++lineNumber;if(line.empty()||line[0]=='#')continue;std::istringstream row(line);Primary primary;if(settings.inputMode=="native"||settings.inputMode=="pdg"){if(!(row>>primary.pdg>>primary.px>>primary.py>>primary.pz>>primary.x>>primary.y>>primary.z))throw std::runtime_error("Invalid native row "+std::to_string(lineNumber));}else if(settings.inputMode=="arti"||settings.inputMode=="UseARTI"){int corsika;double energy,theta,phi;std::string shower,primaryId;if(!(row>>corsika>>primary.px>>primary.py>>primary.pz>>primary.x>>primary.y>>primary.z>>shower>>primaryId>>energy>>theta>>phi))throw std::runtime_error("Invalid ARTI row "+std::to_string(lineNumber));primary.pdg=corsikaToPdg(corsika);if(!primary.pdg)throw std::runtime_error("Unsupported CORSIKA id "+std::to_string(corsika));primary.pz=-primary.pz;primary.x/=100.;primary.y/=100.;primary.z/=100.;}else throw std::runtime_error("Unsupported Input.Mode: "+settings.inputMode);output.push_back(primary);}if(output.empty())throw std::runtime_error("Input contains no primaries");return output; }
std::string ResolvePath(const std::filesystem::path& configFile,const std::string& value) { const std::filesystem::path path(value);if(path.is_absolute()||std::filesystem::exists(path))return path.string();return (configFile.parent_path()/path).lexically_normal().string(); }
}  // namespace WCDConfig
