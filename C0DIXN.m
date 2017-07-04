C0DIXN ; VW/SMH - Latte against ASME (French) Drug Interacations;2017-07-04  7:18 PM
 ;;4.0;KBAN LATTE;;;
 ;
 ; Usage is granted to the user under accompanying license.
 ; If you can't find the license, you are not allowed to use the software.
 ;
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
 n i f i=0:0 s i=$o(DRUGS(i)) q:'i  d
 . n rxns,classes s (rxns,classes)=""
 . s rxns=DRUGS(i,"RXN")
 . s classes=DRUGS(i,"CLASS")
 . n all s all=rxns_","_classes
 . n i1,i2
 . f i1=1:1:$l(all,",") f i2=1:1:$l(all,",") i i1'=i2 k DRUGS("PERM",$p(all,",",i1),$p(all,",",i2))
 ;
 ; Try each permuation against the AIXN index in 176.202
 n p1,p2 s (p1,p2)=""
 f  s p1=$o(DRUGS("PERM",p1)) q:p1=""  f  s p2=$o(DRUGS("PERM",p2)) q:p2=""  d
 . i $data(^C0D(176.202,"AIXN",p1,p2)) n ien s ien=$o(^C0D(176.202,"AIXN",p1,p2,"")) w ien,"#"," "
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
