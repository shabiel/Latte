KBANLRXN ; VEN/SMH - Drug-drug checks done via DrugBank.ca through RxNorm;2015-06-02  6:29 AM
	;;3.0;KBAN LATTE;;;Build 9
	; (c) Sam Habiel 2015.
	;
	; Usage is granted to the user under accompanying license.
	; If you can't find the license, you are not allowed to use the software.
	;
	;
	;
INTERACT(INTERACTIONS,DUPCLASS,DRUGS,PROS,NOCHECKDRUGS)	; Private; Drugbank.ca drug interaction/duplicates code
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
	. ; N VAP S VAP=$P(DRUGS(I,"DINID"),"A",2) ; not needed! 
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
	D GETGTM^KBANLDIT(.RETURN,.HEADERS,"RXNORM DI SERVICE","RXNORM IXNS","?rxcuis="_RXNS)	; REST Call
	;
	; Check for status 200 in the REST Caller.
	N RXNOUT,RXNERR
	D DECODE^VPRJSON($NA(RETURN),$NA(RXNOUT),$NA(RXNERR))
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
	I '$data(RXNOUT("fullInteractionTypeGroup")) quit
	;
	N r S r=$NA(RXNOUT("fullInteractionTypeGroup",1))
	N source S source=@r@("sourceName")
	N disclaimer S disclaimer=@r@("sourceDisclaimer")
	N ixnNum s ixnNum=0
	f  s ixnNum=$o(@r@("fullInteractionType",ixnNum)) q:'ixnNum  d
	. ;
	. ; Get pair
	. n rxncui1 s rxncui1=@r@("fullInteractionType",ixnNum,"minConcept",1,"rxcui")
	. n rxncui2 s rxncui2=@r@("fullInteractionType",ixnNum,"minConcept",2,"rxcui")
	. ;
	. n d1,d2
	. s d1=$o(DRUGS("RXN",rxncui1,""))
	. s d2=$o(DRUGS("RXN",rxncui2,""))
	. ;
	. I d2<d1 n temp s temp=d2,d2=d1,d1=temp
	. ;
	. ; fullInteractionType
	. ; fullInteractionTypeGroup
	. n comment
	. s comment=@r@("fullInteractionType",ixnNum,"comment")
	. ;
	. n severity
	. s severity=@r@("fullInteractionType",ixnNum,"interactionPair",1,"severity")
	. i severity="N/A" s severity="S"
	. s INTERACTIONS(d1,d2)=severity
	. ;
	. n description
	. s description=@r@("fullInteractionType",ixnNum,"interactionPair",1,"description")
	. s INTERACTIONS(d1,d2,"shortText")=description
	. s INTERACTIONS(d1,d2,"clinicalEffects")=description
	. ;
	. ;
	. ; Get individual data for each drug
	. ;
	. n r1 s r1=$name(@r@("fullInteractionType",ixnNum,"interactionPair",1,"interactionConcept",1))
	. n r2 s r2=$name(@r@("fullInteractionType",ixnNum,"interactionPair",1,"interactionConcept",2))
	. ;
	. n id1 s id1=@r1@("sourceConceptItem","id")
	. n name1 s name1=@r1@("sourceConceptItem","name")
	. n url1 s url1=@r1@("sourceConceptItem","url")
	. ;
	. n id2 s id2=@r2@("sourceConceptItem","id")
	. n name2 s name2=@r2@("sourceConceptItem","name")
	. n url2 s url2=@r2@("sourceConceptItem","url")
	. ;
	. n title s title=name1_"/"_name2
	. s INTERACTIONS(d1,d2,"TITLE")=title
	. s INTERACTIONS(d1,d2,"monographTitle")=title
	. s INTERACTIONS(d1,d2,"discussion")="More information can be found at the following URLs: "_url1_" and "_url2
	. ;
	. s INTERACTIONS(d1,d2,"source")=source
	. s INTERACTIONS(d1,d2,"disclaimer")=disclaimer
	;
	QUIT
	;
RXN(VUID)	; Private $$; Obtain RxNorm by VUID. Only get RXNS that have NDCs.
	QUIT $$VUI2RXN^C0CRXNLK(VUID) ; Get first RxNorm code
	;
	;
	;
