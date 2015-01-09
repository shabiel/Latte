KBANLATT ; VEN/SMH - Imitate MOCHA Latte Sytle ;2013-08-06  11:19 AM
 ;;0.4;SAM'S INDUSTRIAL CONGLOMORATES;;
 ; (c) Sam Habiel 2013. All rights reserved.
 ;
EN(RESULT,DOCHAND) ; Public; Main Latte XML parser routine
 ; RESULT - HTTPRSP alias for web server; result to send back to browser; ByRef
 ; DOCHAND - MXML Document Hand; By Val
 ;
 ; Header node
 N HDRNODE S HDRNODE=$$XPATH^MXMLPATH(,DOCHAND,"/PEPSRequest/Header")
 I 'HDRNODE S $EC=",UHEADER-NODE-MISSING,"
 ;
 ; Ping Only? If yes, send reply and done.
 I $$VALUE^MXMLDOM(DOCHAND,HDRNODE,"pingOnly")="true" D SENDPING^KBANLWRT(.RESULT) QUIT
 ;
 ; At this point, it's not just a ping. We have to test to see if we have the following requests.
 ;
 ; See if drugDoseCheck, drugTherapyCheck, drugDrugCheck are requested.
 N DRUGDOSECHECK S DRUGDOSECHECK=$$XPATH^MXMLPATH(,DOCHAND,"/PEPSRequest/Body/drugCheck/checks/drugDoseCheck")
 N DRUGTHERAPYCHECK S DRUGTHERAPYCHECK=$$XPATH^MXMLPATH(,DOCHAND,"/PEPSRequest/Body/drugCheck/checks/drugTherapyCheck")
 N DRUGDRUGCHECK S DRUGDRUGCHECK=$$XPATH^MXMLPATH(,DOCHAND,"/PEPSRequest/Body/drugCheck/checks/drugDrugCheck")
 ;
 ; DEBUG.ASSERT that we got one of these. No point otherwise!
 I '(DRUGDOSECHECK!DRUGTHERAPYCHECK!DRUGDRUGCHECK) S $EC=",UNO-OPERATION-REQUESTED,"
 ;
 ; Do the real work here
 N INTERACTIONS DO DGDG(.INTERACTIONS,DOCHAND):DRUGDRUGCHECK
 N DUPCLASS DO DUP(.DUPCLASS,DOCHAND):DRUGTHERAPYCHECK
 ;
 ; (debug note: zwrite INTERACTIONS and DUPCLASS here to see the results of the checks)
 ;
 ; Write the XML back in the RESULT array
 D RESPOND^KBANLWRT(.RESULT,DOCHAND,.INTERACTIONS,.DUPCLASS,DRUGDRUGCHECK,DRUGTHERAPYCHECK,DRUGDOSECHECK)
 ;
 QUIT
 ;
 ; === The rest of the entry points below are private ===
 ;
DUP(DUPCLASS,DOCHAND) ; Private; Duplicate drug-drug check reply
 ; DUPCLASS, return array. See DUPCLASS procedure
 ; DOCHAND, see above.
 ;
 ; Please note dear reader: throughout the routine,
 ; the drug IDs in the various return arrays are actually their
 ; locations in the parsed MXML Document.
 ;
 N PROS S PROS=$$PROSPEC(DOCHAND) ; Prospective only?
 ;
 N DRUGS D DRUGS(.DRUGS,DOCHAND) ; Extract the drugs from the XML document
 ;
 D DUPCLASS(.DUPCLASS,.DRUGS,PROS) ; Perform duplicate class checking
 ;
 QUIT
DGDG(INTERACTIONS,DOCHAND) ; Private; Drug-Drug interaction check reply
 ; INTERACTIONS: Returned array. See INTERACT for definition
 ; DOCHAND, see above.
 ;
 ; Please note dear reader: throughout the routine,
 ; the drug IDs in the various return arrays are actually their
 ; locations in the parsed MXML Document.
 ;
 N PROS S PROS=$$PROSPEC(DOCHAND) ; Prospective only?
 ;
 N DRUGS D DRUGS(.DRUGS,DOCHAND) ; Extract the drugs from the XML document
 ;
 D INTERACT(.INTERACTIONS,.DRUGS,PROS) ; Perform interaction Checking
 ;
 QUIT
 ;
PROSPEC(DOCHAND) ; $$ - Private; Is this Prospective only?
 ; DOCHAND, see above.
 ; Get Prospective Only flag
 ; If we are prospective only, check the prospective drugs against each other and the profile.
 ; DO NOT check profile drugs against each other.
 ;
 ; Get Checks node.
 N CHKSNODE S CHKSNODE=$$XPATH^MXMLPATH(,DOCHAND,"//Body/drugCheck/checks")
 I 'CHKSNODE S $EC=",UCHECKS-NODE-NOT-FOUND,"
 ;
 ; Get prospectiveOnly attribute
 N VALUE S VALUE=$$VALUE^MXMLDOM(DOCHAND,CHKSNODE,"prospectiveOnly")
 N PROSPECTIVEONLY S PROSPECTIVEONLY=0
 I $L(VALUE),$$UP^XLFSTR(VALUE)="TRUE" S PROSPECTIVEONLY=1
 Q PROSPECTIVEONLY
 ;
DRUGS(DRUGS,DOCHAND) ; Procedure - Private; Extract drug data from XML document
 ; DRUGS: Return Array. Pass by Ref.
 ; -- Rosetta Stone:
 ;    DRUGS(MXML NODE ID,"TYPE")="P" for Prospective or "M" for Medication Profile
 ;                       "VUID") ; VUID from the XML
 ;                       "VAPROD") ; Ien in the VA Product File
 ;                       "VAGEN") ; Ien in the VA Generic File
 ;                       "DINID") ; Drug interaction ID used to query file 56 (Drug Interactions)
 ;                       "VACLS") ; VA Drug Class external form (not ien)
 ;
 ;    Index:
 ;    DRUGS("P" or "M",MXML NODE ID)="" ; Used to aid looping in INTERACT
 ;
 ; DOCHAND - See above
 ;
 N PROSPDRUGS ; Prospective Drugs
 D XPATH^MXMLPATH(.PROSPDRUGS,DOCHAND,"//prospectiveDrugs/drug")
 N PROFILEDRUGS ; Profile Drugs
 D XPATH^MXMLPATH(.PROFILEDRUGS,DOCHAND,"//medicationProfile/drug")
 ;
 N X F X="PROSPDRUGS","PROFILEDRUGS" N I S I=0 F  S I=$O(@X@(I)) Q:'I  D  ; Loop through all drug nodes
 . S DRUGS(I,"TYPE")=$S(X="PROSPDRUGS":"P",1:"M")
 . S DRUGS(DRUGS(I,"TYPE"),I)="" ; Cross reference for looping in INTERACT
 . S DRUGS(I,"VUID")=$$VALUE^MXMLDOM(DOCHAND,I,"vuid")
 . I 'DRUGS(I,"VUID") S $EC=",UVUIDMISSING,"
 . N % S %(1)=DRUGS(I,"VUID") S %(2)=1 ; Compound Index to get master entry
 . S DRUGS(I,"VAPROD")=$$FIND1^DIC(50.68,"","QX",.%,"AMASTERVUID")
 . I 'DRUGS(I,"VAPROD") S $EC=",UINVALIDVUID,"
 . S DRUGS(I,"VAGEN")=$$GET1^DIQ(50.68,DRUGS(I,"VAPROD"),.05,"I") ; VA GENERIC ien
 . S DRUGS(I,"VACLS")=$$GET1^DIQ(50.68,DRUGS(I,"VAPROD"),15) ; External VA Drug Class
 . S DRUGS(I,"DINID")=DRUGS(I,"VAGEN")_"A"_DRUGS(I,"VAPROD") ; Drug interaction ID
 QUIT
 ;
INTERACT(INTERACTIONS,DRUGS,PROS) ; Procedure - Private; Check drug interactions
 ; .INTERACTIONS - Return Array
 ; --> Output:
 ;     INTERACTIONS(DRUG NODE 1,DRUG NODE 2)=S or C (Significant or Critical)
 ;     INTERACTIONS(DRUG NODE 1,DRUG NODE 2,"TITLE")=INTERACTION TITLE
 ; .DRUGS - Input Array as above
 ; PROS - Is this prospective only? (Boolean)
 ;
 ; If prospective only, check interactions against each other and
 ; and check interactions against profile medications for each.
 ;
 ; if not prospective only, check interactions for all medications.
 ;
 ; Please note, subscripts I and J are nodes in the XML document still...
 ; We will still use those.
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
 QUIT
 ;
INTERAC2(INTERACTIONS,DRUGS,I,J) ; Private; Core drug interaction code
 ; INTERACTIONS - Return array as above
 ; I, J are DRUGS array subscripts.
 N DINID1 S DINID1=DRUGS(I,"DINID") ; Grab ID
 N DINID2 S DINID2=DRUGS(J,"DINID") ; ditto
 N INT S INT=$O(^PS(56,"APD",DINID1,DINID2,"")) ; Check drug interaction table
 I 'INT QUIT  ; No interaction found
 N SEVERITY
 S SEVERITY=$P(^PS(56,INT,0),U,4)
 S SEVERITY=$S(SEVERITY=1:"C",1:"S") ; Critical or Significant
 S INTERACTIONS(I,J)=SEVERITY ; Return array
 S INTERACTIONS(I,J,"TITLE")=$P(^PS(56,INT,0),U)
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
TEST ; M-Unit Entry point for Unit Testing the MOCHA Interface
 S IO=$PRINCIPAL
 N DIQUIET S DIQUIET=1
 D DT^DICRW
 D EN^XTMUNIT($T(+0),1)
 QUIT
 ;
CONCHK ; @TEST - Connection Check
 N STATUS S STATUS=$$CONCHK^PSSHRIT()
 D CHKEQ^XTMUNIT(STATUS,1,"Connection check failed.")
 QUIT
 ;
INTERTST ; @TEST - Drug-Drug Interaction Check
 N STATUS S STATUS=$$INTERACT^PSSHRIT()
 D CHKEQ^XTMUNIT(STATUS,1,"Drug-drug interaction check failed")
 QUIT
 ;
DUPTHRPY ; @TEST - Duplicate therapy check
 N STATUS S STATUS=$$DUPTHRPY^PSSHRIT()
 D CHKEQ^XTMUNIT(STATUS,1,"Duplicate therapy check failed")
 QUIT
 ;
DOSECHK ; @TEST - Abnormal Dose Check
 N STATUS S STATUS=$$DOSECHK^PSSHRIT()
 D CHKEQ^XTMUNIT(STATUS,1,"Abnormal Dose Check failed")
 QUIT
 ;
CUSTOM ; @TEST - Custom drug-drug interaction check
 N STATUS S STATUS=$$CUSTOM^PSSHRIT()
 D CHKEQ^XTMUNIT(STATUS,1,"Custom drug-drug interaction check")
 QUIT
