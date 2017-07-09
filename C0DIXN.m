C0DIXN ; VW/SMH - Latte against ANSM (French) Drug Interacations;2017-07-09  1:43 PM
 ;;4.0;KBAN LATTE;;;
 ;
 ; Usage is granted to the user under accompanying license.
 ; If you can't find the license, you are not allowed to use the software.
 ;
 ;
INTERACT(interactions,DUPCLASS,DRUGS,PROS,NOCHECKDRUGS) ; Private
 ; interactions: Return Array. Pass by Ref. Starts empty. 
 ; -- Rosetta Stone:
 ;    interactions(MXML NODE ID OF DRUG1 (D1), DITTO DRUG2 (D2))="C or S"
 ;                               i.e. Critical or Significant
 ;    interactions(D1,D2,"TITLE")="Title of Interaction, usu drug1/drug2)
 ;    interactions(D1,D2,"source")="DIT" ; hardcoded
 ;    interactions(D1,D2,"shortText")="Short interaction description"
 ;    interactions(D1,D2,"disclaimer")="Drug information vendor disclaimer"
 ;    interactions(D1,D2,"monographTitle")="Title for Monograph statement"
 ;    interactions(D1,D2,"severityLevel")="Description of severity of interaction in more detail"
 ;    interactions(D1,D2,"mechanismOfAction")="Mechanism string"
 ;    interactions(D1,D2,"clinicalEffects")="Detailed clinical effects"
 ;    interactions(D1,D2,"preDisposingFactors")="Pre-disposing factors for interaction"
 ;    interactions(D1,D2,"patientManagement")="How to deal with the interactions"
 ;    interactions(D1,D2,"discussion")="Further information"
 ; 
 ; DUPCLASS - Return array. Pass by Ref. Starts empty.
 ; -- Rosetta Stone:
 ;    DUPCLASS(Drug Node ID 1, Drug Node ID 2)=Duplicate Class Name (full name/external)
 ;    DUPCLASS(D1,D2,"duplicateAllowance")=Duplication allowance (hardcoded to zero here)
 ;    DUPCLASS(D1,D2,"shortText")="Description of the duplication"
 ;    DUPCLASS(D1,D2,"source")="DIT" ; hardcoded
 ;
 ;
 ; DRUGS: Reference Array containing drugs to check for ixns.  Pass by Ref.
 ; -- Rosetta Stone:
 ;    DRUGS(MXML NODE ID,"TYPE")="P" for Prospective or "M" for Medication Profile
 ;                       "VUID") ; VUID from the XML
 ;                       "VAPROD") ; Ien in the VA Product File
 ;                       "VAGEN") ; Ien in the VA Generic File
 ;                       "DINID") ; Drug interaction ID used to query file 56 (Drug Interactions)
 ;                       "VACLS") ; VA Drug Class external form (not ien)
 ;                       "RXN")   ; RxNorm IN CUI (output)
 ;                       "NM")    ; Drug Name extracted from VISTA MOCHA message
 ;                       "NOIXN") ; File 50.68,23 says don't track interaction for this drug.
 ;
 ;    Indexes:
 ;    DRUGS("M" --> Med Profile drugs
 ;    DRUGS("P" --> Prospective drugs
 ;    DRUGS("RXN" --> RXNCUI index (output)
 ;
 ; PROS: By value: Is this interaction check for prospective drugs only?
 ;                 In general, this is not used as we pull the prospective
 ;                 flags from the drugs themselves; yet we support it.
 ;
 ; NOCHECKDRUGS -> In case we fail to find an RxNorm match
 ; to a drug, we put it here so that it be reported back
 ; to the user that we failed to do a drug match.
 ; By Ref. May already contain other drugs we couldn't check
 ; from KBANLATT.
 ;
 ; Collect Ingredient VUIDs then RxNorm Codes corresponding to these
 n u s u="^"
 N I F I=0:0 S I=$O(DRUGS(I)) Q:'I  D
 . ;
 . ; Get VUID for VA Generic
 . N VAGEN S VAGEN=DRUGS(I,"VAGEN")
 . N INVUID S INVUID=$$GET1^DIQ(50.6,VAGEN,"VUID")
 . ;
 . ; Get RxNorm associate with VA Generic
 . N RXN S RXN=$$RXN(INVUID)
 . I RXN="" DO  QUIT  ; Remove drug from list if no suitable RxNorm
 . . S NOCHECKDRUGS(I)=""
 . . K DRUGS(I)
 . . N S F S="M","P","RXN" K DRUGS(S,I) ; Remove indexes
 . ;
 . ; Get all other associated RxNorms that could also reference this VA Generic
 . ; (ingredients of multi-form drugs, salts of drugs, single form of salts)
 . N OTHERRXNS S OTHERRXNS=$$PRXN(RXN)
 . S DRUGS(I,"RXN")=$S(OTHERRXNS]"":RXN_","_OTHERRXNS,1:RXN)
 . N J,ONE F J=1:1:$L(DRUGS(I,"RXN"),",") S ONE=$P(DRUGS(I,"RXN"),",",J),DRUGS("RXN",ONE)=I ; Index
 . ;
 . ; Get all the classes in the French Drug Interactions that are associated
 . ; with the rxnorm codes just collected above.
 . N classCodes s classCodes=""
 . N J F J=1:1:$L(DRUGS(I,"RXN"),",") D
 .. N rxn S rxn=$P(DRUGS(I,"RXN"),",",J)
 .. n classIEN
 .. f classIEN=0:0 s classIEN=$O(^C0D(176.201,"RXNCUI",rxn,classIEN)) q:'classIEN  d
 ... n classCode s classCode=$p(^C0D(176.201,classIEN,0),U,2)
 ... s classCodes=classCodes_classCode_","
 . i $e(classCodes,$l(classCodes))="," s $e(classCodes,$l(classCodes))=""
 . S DRUGS(I,"CLASS")=classCodes
 . N J,ONE F J=1:1:$L(DRUGS(I,"CLASS"),",") S ONE=$P(DRUGS(I,"CLASS"),",",J),DRUGS("CLASS",ONE)=I ; Index
 ;
 ; Permute all classes and rxnorms together in nP2 format
 n i,rxns,classes s (rxns,classes)=""
 f i=0:0 s i=$o(DRUGS(i)) q:'i  s rxns=rxns_DRUGS(i,"RXN")_","
 s $e(rxns,$l(rxns))=""
 f i=0:0 s i=$o(DRUGS(i)) q:'i  s classes=classes_DRUGS(i,"CLASS")_","
 s $e(classes,$l(classes))=""
 n all s all=rxns_","_classes
 n i1,i2
 f i1=1:1:$l(all,",") f i2=1:1:$l(all,",") i i1'=i2 s DRUGS("PERM",$p(all,",",i1),$p(all,",",i2))=""
 ;
 ; Remove the permutations of the drugs within themselves
 ;n i f i=0:0 s i=$o(DRUGS(i)) q:'i  d
 ;. n rxns,classes s (rxns,classes)=""
 ;. s rxns=DRUGS(i,"RXN")
 ;. s classes=DRUGS(i,"CLASS")
 ;. n all s all=rxns_","_classes
 ;. n i1,i2
 ;. f i1=1:1:$l(all,",") f i2=1:1:$l(all,",") i i1'=i2 k DRUGS("PERM",$p(all,",",i1),$p(all,",",i2))
 ;
 ; Try each permuation against the AIXN index in 176.202 collect in ixns array
 ; in a deduplicated manner
 n ixns
 n p1,p2 s (p1,p2)=""
 f  s p1=$o(DRUGS("PERM",p1)) q:p1=""  f  s p2=$o(DRUGS("PERM",p2)) q:p2=""  d
 . i $data(^C0D(176.202,"AIXN",p1,p2)) n ien s ien=$o(^C0D(176.202,"AIXN",p1,p2,"")) d
 .. n d1,d1
 .. s d1=^C0D(176.202,ien,0),d2=^C0D(176.202,ien,2)
 .. n d1id s d1id=$s($p(d1,u,2)]"":$p(d1,u,2),1:$p(d1,u,3)) ; 2nd (rxnorm) or 3rd (class)
 .. n d2id s d2id=$s($p(d2,u,2)]"":$p(d2,u,2),1:$p(d2,u,3)) ; ditto
 .. ;
 .. ; Don't store interaction twice:
 .. ; NB: De-Morgan's law to reduce (not a & not b) expression to not(a!b)
 .. i '($d(ixns(d1id,d2id))!$d(ixns(d2id,d1id))) s ixns(d1id,d2id)=ien
 .. ; s ixns(d1id,d2id)=ien
 ;
 ; Now figure out the drugs that caused the interaction, and populate
 ; _interactions_ array
 n id1,id2 s (id1,id2)=""
 f  s id1=$o(ixns(id1)) q:id1=""  f  s id2=$o(ixns(id1,id2)) q:id2=""  d
 . n drug1 s drug1=$s($d(DRUGS("RXN",id1)):DRUGS("RXN",id1),1:DRUGS("CLASS",id1))
 . n drug2 s drug2=$s($d(DRUGS("RXN",id2)):DRUGS("RXN",id2),1:DRUGS("CLASS",id2))
 . i drug1=drug2 quit
 . n ien s ien=ixns(id1,id2)
 . s interactions(drug1,drug2)=^C0D(176.202,ien,4)
 . s interactions(drug1,drug2,"TITLE")=$p(^C0D(176.202,ien,0),u)_"/"_$p(^C0D(176.202,ien,2),u)
 . s interactions(drug1,drug2,"source")="(C) ANSM: Agence nationale de securite du medicament et des produits de sante, France" ; hardcoded
 . s interactions(drug1,drug2,"shortText")=interactions(drug1,drug2,"TITLE")
 . s interactions(drug1,drug2,"disclaimer")=interactions(drug1,drug2,"source")
 . s interactions(drug1,drug2,"monographTitle")=interactions(drug1,drug2,"TITLE")
 . s interactions(drug1,drug2,"severityLevel")=$$GET1^DIQ(176.202,ien,4)
 . n clin n % s %=$$GET1^DIQ(176.202,ien,5,"",$na(clin))
 . s interactions(drug1,drug2,"clinicalEffects")=""
 . n % f %=0:0 s %=$o(clin(%)) q:'%  s interactions(drug1,drug2,"clinicalEffects")=interactions(drug1,drug2,"clinicalEffects")_clin(%)_" "
 . n mang n % s %=$$GET1^DIQ(176.202,ien,6,"",$na(mang))
 . m interactions(drug1,drug2,"patientManagement")=mang
 . ;
 . s interactions(drug1,drug2,"mechanismOfAction",1)="See CLINICAL EFFECTS section"
 . s interactions(drug1,drug2,"preDisposingFactors")=""
 . s interactions(drug1,drug2,"discussion")="See PATIENT MANAGEMENT section"
 ;
 zwrite:$d(interactions) interactions
 ;
 DO DUPCLASS(.DUPCLASS,.DRUGS,PROS)
 QUIT
 ;
RXN(INVUID) ; [$$ Private] IN RxNorm for this Ingredient/VA Generic
 ; Input: VA Generic VUID
 ; Output: rxn
 ;
 Q $$VUI2RXN^C0CRXNLK(INVUID,"IN")
 ;
PRXN(inrxn) ; [$$ Private] Get precise ingredients if possible
 ;
 ; TODO: Move this api to the RxNorm package
 ;
 n rxns s rxns=""
 n ix
 for ix="part_of","form_of","has_form" do
 . n rxn for rxn=0:0 s rxn=$o(^C0CRXN(176.005,"B",inrxn,ix,rxn)) q:'rxn  s rxns=rxns_rxn_","
 i $e(rxns,$l(rxns))="," s $e(rxns,$l(rxns))=""
 quit rxns
 ;
DUPCLASS(DUPCLASS,DRUGS,PROS) ; Private Proc; Perform duplicate class checking
 ; Output:
 ; DUPCLASS - Return array formatted as 
 ; - DUPCLASS(Drug Node ID 1, Drug Node ID 2)=Duplicate Class Name (full name/external)
 ; 
 ; ;
 ; Input:
 ; - DRUGS: Drugs array, as outlined above (by Ref)
 ; - PROS: Boolean for Prospective Only (By Value)
 ;
 ; Simulated error for Unit tests
 ; ZEXCEPT: KBANSIMERR
 I $D(KBANSIMERR) S $EC=",U-SIMULATED-ERROR,"
 ;
 N DONELIST ; A tracker to make sure we don't test stuff against each other again.
 IF PROS DO
 . ; Loop 1: Check prospective drugs against each other; Concentric loops; There must be an easier way to do this.
 . N I S I=0 F  S I=$O(DRUGS("P",I)) Q:'I  N J S J=0 F  S J=$O(DRUGS("P",J)) Q:'J  D
 . . ;
 . . I I=J QUIT  ; Same drug
 . . I $D(DONELIST(I,J)) QUIT  ; Already done
 . . I $D(DONELIST(J,I)) QUIT  ; ditto
 . . D DUPCLAS2(.DUPCLASS,.DRUGS,I,J)
 . . S DONELIST(I,J)=""
 . ;
 . ;
 . ; Loop 2: Check prospective drugs against profile; Concentric loops -- this one is easier!!!
 . N I S I=0 F  S I=$O(DRUGS("P",I)) Q:'I  N J S J=0 F  S J=$O(DRUGS("M",J)) Q:'J  D
 . . D DUPCLAS2(.DUPCLASS,.DRUGS,I,J)
 ;
 ELSE  DO
 . ; Only a single loop. Check all drugs against each other.
 . N I S I=0 F  S I=$O(DRUGS(I)) Q:'I  N J S J=0 F  S J=$O(DRUGS(J)) Q:'J  D
 . . ;
 . . I I=J QUIT  ; Same drug
 . . I $D(DONELIST(I,J)) QUIT  ; Already done
 . . I $D(DONELIST(J,I)) QUIT  ; ditto
 . . D DUPCLAS2(.DUPCLASS,.DRUGS,I,J)
 . . S DONELIST(I,J)=""
 QUIT
 ;
DUPCLAS2(DUPCLASS,DRUGS,I,J) ; Private Procedure; Perform Duplicate Dose Checking Core function
 ; DUPCLASS - See above
 ; DRUGS - See above
 ; I and J are DRUGS subscripts.
 ;
 ; Code here mirrors code in PSODRDUP
 ;
 N CLS1 S CLS1=$E(DRUGS(I,"VACLS"),1,4) ; Abbreviated Class of first drug
 N CLS2 S CLS2=$E(DRUGS(J,"VACLS"),1,4) ; Abbreviated Class of second drug
 ;
 I CLS1'=CLS2 QUIT  ; Not the same; no duplication
 ;
 I $E(CLS1,1,2)="HA" QUIT  ; no drug interaction checking on Herbals per PSODRDU1 pre-Mocha version.
 I $E(CLS2,1,2)="HA" QUIT  ; ditto
 ;
 ; Otherwise, we have a duplication.
 ; What's the class name?
 ; Do an order using the partial class name (4 chars as above) to get to the base class first which ends with a zero.
 N CLS,IEN S CLS=$O(^PS(50.605,"B",CLS1)) S IEN=$O(^(CLS,"")) ; Code will crash if we can't find the class. Intended!
 N CLASSNAME S CLASSNAME=$P(^PS(50.605,IEN,0),U,2) ; #1 CLASSIFICATION
 S DUPCLASS(I,J)=CLASSNAME
 QUIT
