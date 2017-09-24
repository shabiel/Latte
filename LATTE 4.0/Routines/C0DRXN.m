C0DRXN ; VW/SMH - Drug-drug checks done via DrugBank.ca through RxNorm;2017-09-19  4:33 PM
 ;;4.0;LATTE;;
 ; (c) Sam Habiel 2017.
 ;
 ; Usage is granted to the user under accompanying license.
 ; If you can't find the license, you are not allowed to use the software.
 ;
 ;
INTERACT(INTERACTIONS,DUPCLASS,DRUGS,PROS,NOCHECKDRUGS) ; Private; Drugbank.ca drug interaction/duplicates code
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
 ;    INTERACTIONS(D1,D2,"patientManagement")="How to deal with the interactions"
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
 ;                       ; "NDC")   ; Active NDC for the Drug obtained from RxNorm --> not used anymore.
 ;                       "RXN")   ; RxNorm SCD/CD CUI
 ;                       "NM")    ; Drug Name extracted from VISTA MOCHA message
 ;                       "DITCL") ; DIT Drug Class
 ;                       "NOIXN") ; File 50.68,23 says don't track interaction for this drug.
 ;
 ;    Indexes:
 ;    DRUGS("M" --> Med Profile drugs
 ;    DRUGS("P" --> Prospective drugs
 ;    ; DRUGS("NDC" --> NDC index --> not used anymore.
 ;    DRUGS("RXN" --> RXNCUI index
 ;    DRUGS("SYN10" --> DIT SYN10 index
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
 ; Collect RxNorm codes
 N I F I=0:0 S I=$O(DRUGS(I)) Q:'I  D
 . N VUID S VUID=DRUGS(I,"VUID")
 . ;
 . N RXN S RXN=$$RXN(VUID)
 . I RXN="" DO  QUIT  ; Remove drug from list if no suitable RxNorm
 . . S NOCHECKDRUGS(I)=""
 . . K DRUGS(I)
 . . N S F S="M","P","RXN","SYN10" K DRUGS(S,I) ; Remove indexes
 . S DRUGS(I,"RXN")=RXN
 . S DRUGS("RXN",RXN,I)="" ; Index
 ;
 ; Mash RXNs into + for GET request
 N RXNS S RXNS=""
 N I F I=0:0 S I=$O(DRUGS(I)) Q:'I  S RXNS=RXNS_DRUGS(I,"RXN")_"+"
 S $E(RXNS,$L(RXNS))="" ; rm trailing comma
 ;
 I $L(RXNS,"+")=1 QUIT  ; Only one... no Reactions.
 ;
 N RETURN,HEADERS
 D GETGTM^C0DDIT(.RETURN,.HEADERS,"RXNORM DI SERVICE","RXNORM IXNS","?rxcuis="_RXNS) ; REST Call
 ;
 N DATA
 N ZZZ S ZZZ=$NA(RETURN)
 ; U 0 F  S ZZZ=$Q(@RETURN) Q:ZZZ=""  W ZZZ,! U IO
 ;
 ; Check for status 200 in the REST Caller.
 N RXNOUT,RXNERR
 D DECODE^XLFJSON($NA(RETURN),$NA(RXNOUT),$NA(RXNERR))
 I $D(RXNERR) S $EC=",U-JSON-CONV-FAILED,"
 ;
 ;    * INTERACTIONS(MXML NODE ID OF DRUG1 (D1), DITTO DRUG2 (D2))="C or S"
 ;                               i.e. Critical or Significant
 ;    * INTERACTIONS(D1,D2,"TITLE")="Title of Interaction, usu drug1/drug2)
 ;    * INTERACTIONS(D1,D2,"source")="DIT" ; hardcoded
 ;    * INTERACTIONS(D1,D2,"shortText")="Short interaction description"
 ;    * INTERACTIONS(D1,D2,"disclaimer")="Drug information vendor disclaimer"
 ;    * INTERACTIONS(D1,D2,"monographTitle")="Title for Monograph statement"
 ;    * INTERACTIONS(D1,D2,"severityLevel")="Description of severity of interaction in more detail"
 ;    < INTERACTIONS(D1,D2,"mechanismOfAction")="Mechanism string"
 ;    * INTERACTIONS(D1,D2,"clinicalEffects")="Detailed clinical effects"
 ;    < INTERACTIONS(D1,D2,"preDisposingFactors")="Pre-disposing factors for interaction"
 ;    < INTERACTIONS(D1,D2,"patientManagement")="How to deal with the interactions"
 ;    * INTERACTIONS(D1,D2,"discussion")="Further information"
 ;
 if $data(RXNOUT("fullInteractionTypeGroup")) d
 . N r S r=$NA(RXNOUT("fullInteractionTypeGroup",1))
 . N source S source=@r@("sourceName")
 . N disclaimer S disclaimer=@r@("sourceDisclaimer")
 . N ixnNum s ixnNum=0
 . f  s ixnNum=$o(@r@("fullInteractionType",ixnNum)) q:'ixnNum  d
 . . ;
 . . ; Get pair
 . . n rxncui1 s rxncui1=@r@("fullInteractionType",ixnNum,"minConcept",1,"rxcui")
 . . n rxncui2 s rxncui2=@r@("fullInteractionType",ixnNum,"minConcept",2,"rxcui")
 . . ;
 . . n d1,d2
 . . s d1=$o(DRUGS("RXN",rxncui1,""))
 . . s d2=$o(DRUGS("RXN",rxncui2,""))
 . . ;
 . . I d2<d1 n temp s temp=d2,d2=d1,d1=temp
 . . ;
 . . ; fullInteractionType
 . . ; fullInteractionTypeGroup
 . . n comment
 . . s comment=@r@("fullInteractionType",ixnNum,"comment")
 . . ;
 . . n severity
 . . s severity=@r@("fullInteractionType",ixnNum,"interactionPair",1,"severity")
 . . i severity="N/A" s severity="S"
 . . s INTERACTIONS(d1,d2)=severity
 . . ;
 . . n description
 . . s description=@r@("fullInteractionType",ixnNum,"interactionPair",1,"description")
 . . s INTERACTIONS(d1,d2,"shortText")=description
 . . s INTERACTIONS(d1,d2,"clinicalEffects")=description
 . . ;
 . . ;
 . . ; Get individual data for each drug
 . . ;
 . . n r1 s r1=$name(@r@("fullInteractionType",ixnNum,"interactionPair",1,"interactionConcept",1))
 . . n r2 s r2=$name(@r@("fullInteractionType",ixnNum,"interactionPair",1,"interactionConcept",2))
 . . ;
 . . n id1 s id1=@r1@("sourceConceptItem","id")
 . . n name1 s name1=@r1@("sourceConceptItem","name")
 . . n url1 s url1=@r1@("sourceConceptItem","url")
 . . ;
 . . n id2 s id2=@r2@("sourceConceptItem","id")
 . . n name2 s name2=@r2@("sourceConceptItem","name")
 . . n url2 s url2=@r2@("sourceConceptItem","url")
 . . ;
 . . n title s title=name1_"/"_name2
 . . s INTERACTIONS(d1,d2,"TITLE")=title
 . . s INTERACTIONS(d1,d2,"monographTitle")=title
 . . s INTERACTIONS(d1,d2,"discussion")="More information can be found at the following URLs: "_url1_" and "_url2
 . . ;
 . . s INTERACTIONS(d1,d2,"source")=source
 . . s INTERACTIONS(d1,d2,"disclaimer")=disclaimer
 ;
 DO CLEAN(.INTERACTIONS,.DRUGS,PROS)
 DO DUPCLASS(.DUPCLASS,.DRUGS,PROS)
 QUIT
 ;
RXN(VUID) ; Private $$; Obtain RxNorm by VUID. Only get RXNS that have NDCs.
 ; If we have the offline copy of RxNorm in VistA, then use that.
 I $T(VUI2RXN^C0CRXNLK)]"" QUIT +$$VUI2RXN^C0CRXNLK(VUID,"CD") ; Get first RxNorm code
 ;
 ; Otherwise, use RxNorm Web Service to translate VUID
 N RETURN,HEADERS ; idtype=VUID&id=4000631
 D GETGTM^C0DDIT(.RETURN,.HEADERS,"RXNORM DI SERVICE","RXNORM VUID2RXNCUI","?idtype=VUID&id="_VUID) ; REST Call
 N RXNERR,RXNOUT
 D DECODE^XLFJSON($NA(RETURN),$NA(RXNOUT),$NA(RXNERR))
 I $D(RXNERR) S $EC=",U-JSON-CONV-FAILED,"
 Q RXNOUT("idGroup","rxnormId",1)
 ;
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
 ;
CLEAN(IXNS,DRUGS,PROS) ; Private Procedure; Clean Interactions
 ; Pass IXNS and DRUGS by reference.
 ; IXNS modified in place and is the return as well.
 ; 1. Remove interactions between No-interaction drugs (50.68,23)
 ; 2. Remove interactions between Med Profile drugs
 ;
 ; PROS = 1 or 0. Is this a prospective only check?
 ;
 ; 1. Remove interactions between No-interaction drugs (50.68,23)
 N D1,D2
 F D1=0:0 S D1=$O(IXNS(D1)) Q:'D1  F D2=0:0 S D2=$O(IXNS(D1,D2)) Q:'D2  D
 . N D1X,D2X ; Exclude interaction?
 . S D1X=DRUGS(D1,"NOIXN")
 . S D2X=DRUGS(D2,"NOIXN")
 . I (D1X!D2X) K IXNS(D1,D2),IXNS(D2,D1)
 ;
 ; If the check isn't prospective only (i.e. entire profile),
 ; then display all interactions. In our case, don't remove profile drug
 ; interactions
 I 'PROS QUIT
 ;
 ; 2. Remove profile drug interactions/duplications with each other
 N D1,D2
 F D1=0:0 S D1=$O(IXNS(D1)) Q:'D1  F D2=0:0 S D2=$O(IXNS(D1,D2)) Q:'D2  D
 . N D1M,D2M ; Med Profile Drug (Boolean)
 . S D1M=''$D(DRUGS("M",D1))
 . S D2M=''$D(DRUGS("M",D2))
 . I D1M&D2M K IXNS(D1,D2),IXNS(D2,D1)
 QUIT
 ;
