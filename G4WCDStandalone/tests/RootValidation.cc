#include <cmath>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "TFile.h"
#include "TLeaf.h"
#include "TTree.h"

namespace {
constexpr const char* kBranches[] = {"partId", "DetectorId", "px", "py", "pz", "x", "y", "z", "energy_deposit", "charge_pmt_0", "charge_pmt_1", "charge_pmt_2"};
constexpr const char* kTypes[] = {"Int_t", "Int_t", "Double_t", "Double_t", "Double_t", "Double_t", "Double_t", "Double_t", "Double_t", "Int_t", "Int_t", "Int_t"};
TTree* openTree(const char* path, std::unique_ptr<TFile>& file) { file.reset(TFile::Open(path, "READ")); if(!file || file->IsZombie()) throw std::runtime_error(std::string("cannot open ")+path); auto* tree=dynamic_cast<TTree*>(file->Get("Detector")); if(!tree) throw std::runtime_error("missing Detector tree"); return tree; }
void schema(TTree* tree) { for(unsigned i=0;i<std::size(kBranches);++i) { auto* leaf=tree->GetLeaf(kBranches[i]); if(!leaf) throw std::runtime_error(std::string("missing branch ")+kBranches[i]); if(std::string(leaf->GetTypeName())!=kTypes[i]) throw std::runtime_error(std::string("wrong type for ")+kBranches[i]); } }
void compare(TTree* left,TTree* right) { if(left->GetEntries()!=right->GetEntries()) throw std::runtime_error("tree entry counts differ"); std::vector<TLeaf*> a,b; for(const auto* name:kBranches){a.push_back(left->GetLeaf(name));b.push_back(right->GetLeaf(name));} for(Long64_t i=0;i<left->GetEntries();++i){left->GetEntry(i);right->GetEntry(i);for(unsigned j=0;j<a.size();++j)if(std::abs(a[j]->GetValue()-b[j]->GetValue())>1e-12)throw std::runtime_error("single-thread and MT output differ");} }
}
int main(int argc,char** argv) try { if(argc!=3) throw std::runtime_error("usage: WCDRootValidation single.root mt.root"); std::unique_ptr<TFile> one,two; auto* single=openTree(argv[1],one);auto* mt=openTree(argv[2],two);schema(single);schema(mt);if(single->GetEntries()!=2)throw std::runtime_error("entering/in-water primary was lost, or missed primary was incorrectly written");compare(single,mt);return 0;} catch(const std::exception& e){std::cerr<<"WCDRootValidation: "<<e.what()<<'\n';return 1;}
