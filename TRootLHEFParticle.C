#define TRootLHEFParticle_cxx
#include "TRootLHEFParticle.h"
#include <TH2.h>
#include <TStyle.h>
#include <TCanvas.h>

#define motherPID 39
#define min 0
#define max 6500
#define docostheta 0

float kinePP(float m1, float m2, float M){ //this is use to get daughter particles' momentum by mass (1->2 process)
	float pp;
	pp = TMath::Sqrt( (M*M-(m1+m2)*(m1+m2) )*(M*M-(m1-m2)*(m1-m2) ) )/2/M;
	return ( float(pp) );
}

void TRootLHEFParticle::Loop()
{
//   In a ROOT session, you can do:
//      root> .L TRootLHEFParticle.C
//      root> TRootLHEFParticle t
//      root> t.GetEntry(12); // Fill t data members with entry number 12
//      root> t.Show();       // Show values of entry 12
//      root> t.Show(16);     // Read and show values of entry 16
//      root> t.Loop();       // Loop on all entries
//

//     This is the loop skeleton where:
//    jentry is the global entry number in the chain
//    ientry is the entry number in the current Tree
//  Note that the argument to GetEntry must be:
//    jentry for TChain::GetEntry
//    ientry for TTree::GetEntry and TBranch::GetEntry
//
//       To read only selected branches, Insert statements like:
// METHOD1:
//    fChain->SetBranchStatus("*",0);  // disable all branches
//    fChain->SetBranchStatus("branchname",1);  // activate branchname
// METHOD2: replace line
//    fChain->GetEntry(jentry);       //read all branches
//by  b_branchname->GetEntry(ientry); //read only this branch

	if (fChain == 0) return;

//add some hist.
	TH1F *h_higgsPt[3];
	TH1F *h_higgsPz[3];
	TH1F *h_higgsP[3];
   TH1F *h_higgsRap[3];
   TH1F *h_nH = new TH1F("h_nM","h_nM",4,0,4);
   TH1F *h_hhDeltaR = new TH1F("h_hhDeltaR","h_hhDeltaR",60,2,5);
   TH1F *h_hhM = new TH1F("h_hhNewResonanceM","h_hhNewResonanceM",100,min,max);
	TH1F *h_hheta = new TH1F("h_hhDeltaEta","h_hhDeltaEta",40,0,10);
	TH1F *h_hhPhi = new TH1F("h_hhDeltaPhi","h_hhDeltaPhi",40,0,10);
	TH1F *h_motherM = new TH1F("h_motherM","h_motherM",100,min,max);
	TH1F *h_motherPT = new TH1F("h_motherPT","h_motherPT",40,0,2000);
	TH1F *h_PID = new TH1F("h_PID","h_PID",20,20,40); 
	TH1F *h_count = new TH1F("h_count","0 for strange momentum, 1 for no mother particle in entries",2,0,2);
	TH1F *h_cos = new TH1F("h_costheta","h_costheta*",200,-1,1);

//define matrix form hist
   string text[3] = {"higgs1","higgs2","NewResonance"}; // covenient to input names by orders	
	string text_2[3] = {"higgs1","higgs2","kine"};
   for (int i=0;i<3;i++) {
   	h_higgsPt[i] = new TH1F(Form("h_%sPt",text[i].data()),Form("h_%sPt",text[i].data()),40,0,2000);
   	h_higgsPz[i] = new TH1F(Form("h_%sPz",text[i].data()),Form("h_%sPz",text[i].data()),40,-2000,2000);
   	h_higgsRap[i] = new TH1F(Form("h_%sRapidity",text[i].data()),Form("h_%sRapidity",text[i].data()),60,-3,3);
		h_higgsP[i] = new TH1F(Form("h_%sP",text_2[i].data()),Form("h_%sP",text_2[i].data()),80,0,2000);
   }
//some define variables
	//for delta eta
	double higgsEta[2];
	//for hhM
	double higgsM[2];

	//origin code for reading root file & compute size of file
	Long64_t nentries = fChain->GetEntriesFast();
   Long64_t nbytes = 0, nb = 0;
   const Int_t nPar = kMaxParticle;
// run all of the entries
   for (Int_t jentry=0; jentry<nentries;jentry++) {
	   Long64_t ientry = LoadTree(jentry);
      if (ientry < 0) break;
      Int_t nHiggs = 0, nhh = 0;
		int nMother = 0; 
	//setting mother particle params
	 	float motherM;
	 	float motherE;
	 	float motherPz;
	 	int motherCheck = -1; //-1 means no mother; 0 means having		
      Int_t hIndex[2] = {-1,-1};
      TLorentzVector higgsVect[2];	

	//the main work --choose particle & record
		for (int i=0;i<Particle_size;i++) {
			h_PID->Fill(Particle_PID[i]);
			switch(Particle_PID[i]){
			case 25: 
				nhh++; //PID==25 for higgs
           	if (nHiggs<2) {
              	h_higgsPt[nHiggs]->Fill(Particle_PT[i]);
              	h_higgsPz[nHiggs]->Fill(Particle_Pz[i]);
              	h_higgsRap[nHiggs]->Fill(Particle_Rapidity[i]);
              	higgsVect[nHiggs].SetPxPyPzE(Particle_Px[i],Particle_Py[i],Particle_Pz[i],Particle_E[i]);
              	hIndex[nHiggs] = i;
					higgsEta[nHiggs] = Particle_Eta[i];
					higgsM[nHiggs] = Particle_M[i];
              	nHiggs++;
           	}
				break;
			case motherPID:
				nMother++;
				motherM = Particle_M[i];
				motherE = Particle_E[i];
				motherPz = Particle_Pz[i];
				motherCheck = 0; 
				h_motherM->Fill(Particle_M[i]);
				h_motherPT->Fill(Particle_PT[i]);
				break;
			}		
		}//end of scan particle in one entry

	//select entries content over 2 higgs
      if (nhh>2) cout << jentry << endl;
      h_nH->Fill(nMother);
		//normally there two values in hIndex showing that it sure has two higgs, so we can continue to record the data.
      if (hIndex[1]>=0&&hIndex[0]>=0) {
        TLorentzVector ResonanceVect = higgsVect[0] + higgsVect[1];
        h_higgsPt[2]->Fill(ResonanceVect.Pt());
        h_higgsPz[2]->Fill(ResonanceVect.Pz());
		  float kineTemp = kinePP(float(higgsM[0]),float(higgsM[1]),motherM);
		  h_higgsP[2]->Fill(kineTemp);
        h_higgsRap[2]->Fill(Particle_Rapidity[hIndex[0]]+Particle_Rapidity[hIndex[1]]);
        h_hhDeltaR->Fill(higgsVect[0].DeltaR(higgsVect[1]));	
        h_hhM->Fill((higgsVect[0]+higgsVect[1]).M());
		  if (higgsEta[0]>higgsEta[1]) h_hheta->Fill( higgsEta[0]-higgsEta[1] );
		  else h_hheta->Fill( higgsEta[1]-higgsEta[0] );
		  h_hhPhi->Fill(higgsVect[0].DeltaPhi(higgsVect[1]));
		  //do Lorentz boost to the Mother particle's rest frame
		  if (motherCheck == -1) {
			//	std::cout << jentry << " there is no mother particle in this entry." << std::endl;// print out the entries don't have mother particle
				h_count->Fill(1);
		  }
		  higgsVect[0].Boost(0,0,(float)-1.0*motherPz/motherE);
		  higgsVect[1].Boost(0,0,(float)-1.0*motherPz/motherE);
		  float theta=TMath::ATan(higgsVect[0].Pt()/ higgsVect[0].Pz() );
		  h_cos->Fill( higgsVect[0].Pz()/ higgsVect[0].P() );
		  //if ( theta > 1.57 || theta < -1.57 ) std::cout << cos(TMath::ATan(higgsVect[0].Pt()/ higgsVect[0].Pz() ) ) << " | theta= " << theta << std::endl;
			
		  h_higgsP[0]->Fill(higgsVect[0].P());
		  h_higgsP[1]->Fill(higgsVect[1].P());
		  if ( (higgsVect[0].P() - kineTemp)*(higgsVect[0].P() - kineTemp) > 0.001 and (higgsVect[1].P() - kineTemp)*(higgsVect[1].P() - kineTemp) > 0.001 ) {
			   h_count->Fill(0);
			//	std::cout << "kine= " << kineTemp << " |p1= " << (float)higgsVect[0].P() << " |p2= " << (float)higgsVect[1].P() << " |i= " << jentry << std::endl;
		  }
      }
      nb = fChain->GetEntry(jentry);   nbytes += nb;
   }
// print out the result 
	gStyle->SetOptStat(1111111);//check the "outside" value?
	//	h_higgsP[0]->Draw();
	//	h_higgsP[1]->Draw("SAME");
	//	h_higgsP[2]->Draw("SAME");
//h_cos->Draw();
//new TCanvas;
//h_count->Draw();
int kineResultFM = h_count->GetBinContent(1);
int kineResultF = h_count->GetBinContent(2);

<<<<<<< HEAD
string pdfName = "cmsgrid_final.pdf";
=======
string pdfName = "Radion_hh_width0p10_M1000_slc6_amd64_gcc481_CMSSW_7_1_30_tarball_final.pdf";
>>>>>>> 15a59d4dd517054d414586f28007e066ad8c202c
   TCanvas *c1 = new TCanvas("c1","c1",3);
   c1->Print((pdfName+"[").data());
   h_nH->Draw("hist text 0");
   c1->Print(pdfName.data());
   h_hhM->Draw("hist");
   c1->Print(pdfName.data());
// RooFit
// fit mother particle mass
   using namespace RooFit;
   RooRealVar x("x","new Resonance (GeV)",min,max);
   RooDataHist data("data","new Resonance",x,h_hhM);
   RooRealVar mean("mean","mean",min,max);
   RooRealVar width("width","width",0,3000);
   RooBreitWigner fitFun("fit","fit",x,mean,width);
   fitFun.fitTo(data);
   RooPlot* xframe = x.frame();
   data.plotOn(xframe) ;
   fitFun.plotOn(xframe);
	float z = (float)width.getVal() / mean.getVal();
	float dx = width.getError()/width.getVal();
	float dy = mean.getError()/mean.getVal();
	float err = z * TMath::Sqrt( dx*dx + dy*dy );
   //fitFun.paramOn(xframe,RooArgSet(mean,width));
   fitFun.paramOn(xframe,Layout(0.5,0.9,0.9));
   //fitFun.paramOn(xframe,mean,width);
	//new TCanvas;
	xframe->Draw();
   c1->SetLeftMargin(0.15);
   c1->Print(pdfName.data());
   

// fit costheta*
//int docostheta = 1;

	RooRealVar x2("x2","costheta*",-1,1);
	RooRealVar p1("p1","coeff1",-1,1);
	RooRealVar p2("p2","coeff2",-5,5);
	RooRealVar p3("p3","coeff3",-5,5);
	RooRealVar p4("p4","coeff4",-5,5);
if ( docostheta == 1 ){
	RooDataHist data2("data2","costheta*",x2,h_cos);
	RooPolynomial fitFun2("fit2","fit",x2,RooArgList(p1,p2,p3,p4));
	fitFun2.fitTo(data2);
	RooPlot* xframe2 = x2.frame();
	data2.plotOn(xframe2) ;
	fitFun2.plotOn(xframe2) ;
	fitFun2.paramOn(xframe2,Layout(0.5,0.9,0.9));
	//new TCanvas;
	h_cos->Draw();
	c1->Print(pdfName.data());
	xframe2->Draw();	
	c1->Print(pdfName.data());
	//std::cout << p2.getError() << "this is test" << std::endl;
}
   c1->Print((pdfName+"]").data());
// save all plots into PDF/txt
   ofstream myfile("tmpfile.txt");
	if ( kineResultF == kineResultFM ) myfile << "kinetic test: true\n";
	else myfile << "kinetic test: False\n";
	int a = h_hhM->GetBinLowEdge(h_hhM->GetMaximumBin())+h_hhM->GetBinWidth(h_hhM->GetMaximumBin())/2.0;
	int b = h_motherM->GetBinLowEdge(h_motherM->GetMaximumBin())+h_motherM->GetBinWidth(h_motherM->GetMaximumBin())/2.0;
	if ( (a-b) < 15 )	myfile << "mass test: true\n";
	else myfile << "mass test: False" << " |motherM = " << a << " |higgs mass:" << b << std::endl;
	myfile << "mother particle is " << z*100 << " + " << err*100 << "\n";
	myfile << "mass width = " << width.getVal() << " + " << width.getError() << "\n";
	if ( docostheta == 1 ){
	myfile << "fit:" <<  Form("%.4f", p1.getVal() ) << " | " <<  Form("%.4f", p2.getVal() ) << " | " <<  Form("%.4f", p3.getVal() ) << " | " <<  Form("%.4f", p4.getVal() );
	}
	myfile.close();
}
