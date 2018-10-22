#define TRootLHEFParticle_cxx
#include "TRootLHEFParticle.h"
#include <TH2.h>
#include <TStyle.h>
#include <TCanvas.h>
#define motherPID 39
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
    TH1F *h_higgsRap[3];
    TH1F *h_nH = new TH1F("h_nH","h_nH",8,-0.5,7.5);
    TH1F *h_hhDeltaR = new TH1F("h_hhDeltaR","h_hhDeltaR",60,2,5);
    TH1F *h_hhM = new TH1F("h_hhNewResonanceM","h_hhNewResonanceM",100,500,3500);
	 TH1F *h_hheta = new TH1F("h_hhDeltaEta","h_hhDeltaEta",40,0,10);
	 TH1F *h_hhPhi = new TH1F("h_hhDeltaPhi","h_hhDeltaPhi",40,0,10);
	 TH1F *h_motherM = new TH1F("h_motherM","h_motherM",100,500,3500);
	 TH1F *h_motherPT = new TH1F("h_motherPT","h_motherPT",40,0,2000);
	TH1F *h_PID = new TH1F("h_PID","h_PID",20,20,40); 
//define matrix form hist
    string text[3] = {"higgs1","higgs2","NewResonance"}; // covenient to input names by orders	
    for (int i=0;i<3;i++) {
        h_higgsPt[i] = new TH1F(Form("h_%sPt",text[i].data()),Form("h_%sPt",text[i].data()),40,0,2000);
        h_higgsPz[i] = new TH1F(Form("h_%sPz",text[i].data()),Form("h_%sPz",text[i].data()),40,-2000,2000);
        h_higgsRap[i] = new TH1F(Form("h_%sRapidity",text[i].data()),Form("h_%sRapidity",text[i].data()),60,-3,3);
    }
//some define variables
	//for delta eta
		double h_eta[2];
	//for hhM
		double h_M[2];
//origin code for reading root file & compute size of file
   Long64_t nentries = fChain->GetEntriesFast();
   Long64_t nbytes = 0, nb = 0;
   const Int_t nPar = kMaxParticle;
   for (Int_t jentry=0; jentry<nentries;jentry++) {
       Long64_t ientry = LoadTree(jentry);
      if (ientry < 0) break;
      Int_t nHiggs = 0, nhh = 0;
		int nMother = 0; 
      Int_t hIndex[2] = {-1,-1};
      TLorentzVector higgsVect[2];
      //for (int i=0;i<nPar;i++) {
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
						h_eta[nHiggs] = Particle_Eta[i];
						h_M[nHiggs] = Particle_M[i];
               	nHiggs++;
            	}
					break;
				case 39:
					nMother++;
					h_motherM->Fill(Particle_M[i]);
					h_motherPT->Fill(Particle_PT[i]);
					break;
				}		
				
      }
//select entries content over 2 higgs
      if (nhh>2) cout << jentry << endl;
      h_nH->Fill(nMother);
//normally there two values in hIndex showing that it sure has two higgs, so we can continue to record the data.
      if (hIndex[1]>=0&&hIndex[0]>=0) {
        TLorentzVector ResonanceVect = higgsVect[0] + higgsVect[1];
        h_higgsPt[2]->Fill(ResonanceVect.Pt());
        h_higgsPz[2]->Fill(ResonanceVect.Pz());
        h_higgsRap[2]->Fill(Particle_Rapidity[hIndex[0]]+Particle_Rapidity[hIndex[1]]);
        h_hhDeltaR->Fill(higgsVect[0].DeltaR(higgsVect[1]));	
        h_hhM->Fill((higgsVect[0]+higgsVect[1]).M());
		  if (h_eta[0]>h_eta[1]) h_hheta->Fill( h_eta[0]-h_eta[1] );
		  else h_hheta->Fill( h_eta[1]-h_eta[0] );
		  h_hhPhi->Fill(higgsVect[0].DeltaPhi(higgsVect[1]));
      }
      //if (jentry%100) cout << "ggg  " << ientry << "\t" << jentry << endl;
      // if (Cut(ientry) < 0) continue;
      nb = fChain->GetEntry(jentry);   nbytes += nb;
   }
// save all plots into PDF
   ofstream myfile("tmpfile.txt");
	int a = h_hhM->GetBinLowEdge(h_hhM->GetMaximumBin())+h_hhM->GetBinWidth(h_hhM->GetMaximumBin())/2;
	int b = h_motherM->GetBinLowEdge(h_motherM->GetMaximumBin())+h_motherM->GetBinWidth(h_motherM->GetMaximumBin())/2;
	if ( (a-b) < 15 )	myfile << "true";
	else myfile << "False" << " |" << a << " |" << b;
	myfile.close();
/*	string pdfName = "BulkGraviton_hh_5perWidth_M2200.pdf";
	gStyle->SetOptStat(1111111);//check the "outside" value?
   TCanvas *c1 = new TCanvas("c1","c1",3);
   c1->Print((pdfName+"[").data());
   h_nH->Draw("hist text 0");
   c1->Print(pdfName.data());
   h_hhM->Draw("hist");
   c1->Print(pdfName.data());
   for (int i=0;i<3;i++) {
      h_higgsPt[i]->Draw("hist");
      c1->Print(pdfName.data());
      h_higgsPz[i]->Draw("hist");
      c1->Print(pdfName.data());
      h_higgsRap[i]->Draw("hist");
      c1->Print(pdfName.data());
   }
   h_hhDeltaR->Draw("hist");
   c1->Print(pdfName.data());
	h_hheta->Draw("hist");
	c1->Print(pdfName.data());
	h_hhPhi->Draw("hist");
	c1->Print(pdfName.data());
	h_motherM->Draw("hist");
	c1->Print(pdfName.data());
	h_motherPT->Draw("hist");
	c1->Print(pdfName.data());
// RooFit
   using namespace RooFit;
   RooRealVar x("x","new Resonance (GeV)",500,3500);
   RooDataHist data("data","new Resonance",x,h_hhM);
   RooRealVar mean("mean","mean",2000,6000);
   RooRealVar width("width","width",0,500);
   RooBreitWigner fitFun("fit","fit",x,mean,width);
   fitFun.fitTo(data);
   RooPlot* xframe = x.frame();
   data.plotOn(xframe) ;
   fitFun.plotOn(xframe);
   //fitFun.paramOn(xframe,RooArgSet(mean,width));
   fitFun.paramOn(xframe,Layout(0.5,0.9,0.9));
   //fitFun.paramOn(xframe,mean,width);
   xframe->Draw();
   c1->SetLeftMargin(0.15);
   c1->Print(pdfName.data());
   
   c1->Print((pdfName+"]").data());
   cout << fitFun.getVal() << endl;
   cout << fitFun.getVal(x) << endl;
   cout << fitFun.getVal(mean) << endl;
   cout << fitFun.getVal(width) << endl; */ 
}
