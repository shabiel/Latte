C0DIXN ; VW/SMH - Latte against ANSM (French) Drug Interacations;2017-07-23  2:14 PM
 ;;4.0;KBAN LATTE;;;
 ;
 ; Usage is granted to the user under accompanying license.
 ; If you can't find the license, you are not allowed to use the software.
 ;
 ;
INTERACT(INTERACTIONS,DUPCLASS,DRUGS,PROS,NOCHECKDRUGS) ; Private
 ; INTERACTIONS: Return Array. Pass by Ref. Starts empty. 
 ; -- Rosetta Stone:
 ;    INTERACTIONS(MXML NODE ID OF DRUG1 (D1), DITTO DRUG2 (D2))="C or S"
 ;                               i.e. Critical or Significant
 ;    INTERACTIONS(D1,D2,"TITLE")="Title of Interaction, usu drug1/drug2)
 ;    INTERACTIONS(D1,D2,"source")="DIT" ; hardcoded
 ;    INTERACTIONS(D1,D2,"shortText")="Short interaction description"
 ;    INTERACTIONS(D1,D2,"disclaimer")="Drug information vendor disclaimer"
 ;    INTERACTIONS(D1,D2,"monographTitle")="Title for Monograph statement"
 ;    INTERACTIONS(D1,D2,"severityLevel")="Description of severity of interaction in more detail"
 ;    INTERACTIONS(D1,D2,"mechanismOfAction")="Mechanism string"
 ;    INTERACTIONS(D1,D2,"clinicalEffects")="Detailed clinical effects"
 ;    INTERACTIONS(D1,D2,"preDisposingFactors")="Pre-disposing factors for interaction"
 ;    INTERACTIONS(D1,D2,"patientManagement")="How to deal with the INTERACTIONS"
 ;    INTERACTIONS(D1,D2,"discussion")="Further information"
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
 ; Collect Ingredient VUIDs
 n u s u="^"
 N I F I=0:0 S I=$O(DRUGS(I)) Q:'I  S DRUGS(I,"VAGENVUID")=$$GET1^DIQ(50.6,DRUGS(I,"VAGEN"),"VUID")
 ;
 N DONELIST ; A tracker to make sure we don't test stuff against each other again.
 IF PROS DO
 . ; Loop 1: Check prospective drugs against each other; Concentric loops; There must be an easier way to do this.
 . N I S I=0 F  S I=$O(DRUGS("P",I)) Q:'I  N J S J=0 F  S J=$O(DRUGS("P",J)) Q:'J  D
 . . ;
 . . I I=J QUIT  ; Same drug
 . . I $D(DONELIST(I,J)) QUIT  ; Already done
 . . I $D(DONELIST(J,I)) QUIT  ; ditto
 . . D INTERAC2(.INTERACTIONS,.DRUGS,I,J)
 . . S DONELIST(I,J)=""
 . ;
 . ;
 . ; Loop 2: Check prospective drugs against profile; Concentric loops -- this one is easier!!!
 . N I S I=0 F  S I=$O(DRUGS("P",I)) Q:'I  N J S J=0 F  S J=$O(DRUGS("M",J)) Q:'J  D
 . . D INTERAC2(.INTERACTIONS,.DRUGS,I,J)
 ;
 ELSE  DO
 . ; Only a single loop. Check all drugs against each other.
 . N I S I=0 F  S I=$O(DRUGS(I)) Q:'I  N J S J=0 F  S J=$O(DRUGS(J)) Q:'J  D
 . . ;
 . . I I=J QUIT  ; Same drug
 . . I $D(DONELIST(I,J)) QUIT  ; Already done
 . . I $D(DONELIST(J,I)) QUIT  ; ditto
 . . D INTERAC2(.INTERACTIONS,.DRUGS,I,J)
 . . S DONELIST(I,J)=""
 zwrite:$d(INTERACTIONS) INTERACTIONS
 DO DUPCLASS(.DUPCLASS,.DRUGS,PROS)
 QUIT
 ;
INTERAC2(INTERACTIONS,DRUGS,I,J) ; Private; Core drug interaction code
 ; INTERACTIONS - Return array as above
 ; I, J are DRUGS array subscripts.
 N INVUID1 S INVUID1=DRUGS(I,"VAGENVUID") ; Ingredient VUID 1
 N INVUID2 S INVUID2=DRUGS(J,"VAGENVUID") ; ditto
 ;
 ; Collect Interactions
 N IXN,IXNS
 F IXN=0:0 S IXN=$O(^C0D(176.202,"AIXN",INVUID1,INVUID2,IXN)) Q:'IXN  S IXNS(IXN)=""
 F IXN=0:0 S IXN=$O(^C0D(176.202,"AIXN",INVUID2,INVUID1,IXN)) Q:'IXN  S IXNS(IXN)=""
 F IXN=0:0 S IXN=$O(IXNS(IXN)) Q:'IXN  D
 . n drug1,drug2,ien
 . s u="^"
 . s ien=IXN
 . s drug1=I,drug2=J
 . s INTERACTIONS(drug1,drug2)=^C0D(176.202,ien,4)
 . s INTERACTIONS(drug1,drug2,"TITLE")=$p(^C0D(176.202,ien,0),u)_"/"_$p(^C0D(176.202,ien,2),u)
 . s INTERACTIONS(drug1,drug2,"source")="(C) ANSM: Agence nationale de securite du medicament et des produits de sante, France" ; hardcoded
 . s INTERACTIONS(drug1,drug2,"shortText")=INTERACTIONS(drug1,drug2,"TITLE")
 . s INTERACTIONS(drug1,drug2,"disclaimer")=INTERACTIONS(drug1,drug2,"source")
 . s INTERACTIONS(drug1,drug2,"monographTitle")=INTERACTIONS(drug1,drug2,"TITLE")
 . s INTERACTIONS(drug1,drug2,"severityLevel")=$$GET1^DIQ(176.202,ien,4)
 . n clin n % s %=$$GET1^DIQ(176.202,ien,5,"",$na(clin))
 . s INTERACTIONS(drug1,drug2,"clinicalEffects")=""
 . n % f %=0:0 s %=$o(clin(%)) q:'%  s INTERACTIONS(drug1,drug2,"clinicalEffects")=INTERACTIONS(drug1,drug2,"clinicalEffects")_clin(%)_" "
 . n mang n % s %=$$GET1^DIQ(176.202,ien,6,"",$na(mang))
 . m INTERACTIONS(drug1,drug2,"patientManagement")=mang
 . ;
 . s INTERACTIONS(drug1,drug2,"mechanismOfAction",1)="See CLINICAL EFFECTS section"
 . s INTERACTIONS(drug1,drug2,"preDisposingFactors")=""
 . s INTERACTIONS(drug1,drug2,"discussion")="See PATIENT MANAGEMENT section"
 QUIT
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
