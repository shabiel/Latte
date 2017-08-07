KBANLDIT ; VEN/SMH - Latte against DIT;2015-01-09  1:40 PM
 ;;3.0;KBAN LATTE;;;Build 12
 ; (c) Sam Habiel 2013.
 ;
 ; Usage is granted to the user under accompanying license.
 ; If you can't find the license, you are not allowed to use the software.
 ;
 ;
 ;
INTERACT(INTERACTIONS,DUPCLASS,DRUGS,PROS,NOCHECKDRUGS) ; Private; DIT drug interaction/duplicates code
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
 ; Mash RXNs into CSVs
 N RXNS S RXNS=""
 N I F I=0:0 S I=$O(DRUGS(I)) Q:'I  S RXNS=RXNS_DRUGS(I,"RXN")_","
 S $E(RXNS,$L(RXNS))="" ; rm trailing comma
 ;
 I $L(RXNS,",")=1 QUIT  ; Only one... no Reactions.
 ;
 ; Get syn10 codes and drug classes for each of the drugs using DIT Drug Info call
 D DITINFO(.DRUGS)
 ;
 ;DEBUG
 ;ZWRITE DRUGS
 ;DEBUG
 ;
 ; Run web service call for drug interaction
 N IXNS ; Interactions
 D DITDI(.IXNS,RXNS)
 ;
 ; DEBUG
 ; ZWRITE IXNS
 ; DEBUG
 ;
 ; Remove interactions for profile drugs against other profile drugs
 ; && remove unimportant interactions && remove exluded interactions per
 ; file 50.68,23
 D CLEAN(.IXNS,.DRUGS,PROS)
 ;
 ; Get Monographs for Interaction
 N I F I=0:0 S I=$O(IXNS(I)) Q:'I  D
 . I (IXNS(I,"InteractionCcode")=11111111) DO  QUIT  ; Duplicate drug code. Doesn't return anything from web service.
 .. S IXNS(I,"Management")=""
 .. S IXNS(I,"Mechanism")=""
 . N MGMT,MECH
 . D DITDIM(IXNS(I,"InteractionCcode"),.MGMT,.MECH)
 . M IXNS(I,"Management")=MGMT
 . M IXNS(I,"Mechanism")=MECH
 ;
 ; DEBUG
 ; ZWRITE IXNS R %
 ; DEBUG
 ;
 ; Construct return array (DUPCLASS)
 N I F I=0:0 S I=$O(IXNS(I)) Q:'I  D
 . I $$UP^XLFSTR(IXNS(I,"EffLong"))'["DUPLICATE THERAPY" QUIT
 . ;
 . N SYN1 S SYN1=IXNS(I,"SynCcode1")
 . N SYN2 S SYN2=IXNS(I,"SynCcode2")
 . N D1 S D1=$O(DRUGS("SYN10",SYN1,""))
 . N D2 S D2=$O(DRUGS("SYN10",SYN2,""))
 . ;
 . I 'D1!('D2) S $EC=",U-SYN-CODES-DONT-MATCH,"
 . ;
 . I D1>D2 N T S T=D1,D1=D2,D2=T K T ; b/c of the finicky requirements of interface, make sure first and second drug are in the right order.
 . ;
 . S DUPCLASS(D1,D2)=DRUGS(D1,"DITCL")
 . S DUPCLASS(D1,D2,"source")="DIT" ; hardcoded
 . S DUPCLASS(D1,D2,"duplicateAllowance")=0 ; hardcoded for now
 . S DUPCLASS(D1,D2,"shortText")="Use of "_DRUGS(D1,"NM")_" and "_DRUGS(D2,"NM")_" may represent a duplication in therapy based on their association to the therapeutic drug class "_DRUGS(D1,"DITCL")
 ;
 ; Construct return array (INTERACTIONS)
 N I F I=0:0 S I=$O(IXNS(I)) Q:'I  D
 . I $$UP^XLFSTR(IXNS(I,"EffLong"))["DUPLICATE THERAPY" QUIT
 . N SYN1 S SYN1=IXNS(I,"SynCcode1")
 . N SYN2 S SYN2=IXNS(I,"SynCcode2")
 . N D1 S D1=$O(DRUGS("SYN10",SYN1,""))
 . N D2 S D2=$O(DRUGS("SYN10",SYN2,""))
 . ; 
 . I D1>D2 N T S T=D1,D1=D2,D2=T K T ; b/c of the finicky requirements of interface, make sure first and second drug are in the right order.
 . ;
 . I 'D1!('D2) S $EC=",U-SYN-CODES-DONT-MATCH,"
 . ;
 . ; DEBUG ONLY - VISTA INTERACTIONS FOR COMPARISON
 . ;  D INTERAC2^KBANLATT(.INTERACTIONS,.DRUGS,D1,D2)
 . ;  N VISTASEV S VISTASEV=$GET(INTERACTIONS(D1,D2))
 . ; END DEBUG
 . ;
 . S INTERACTIONS(D1,D2)=$$SEVERITY(IXNS(I,"Relevance"),IXNS(I,"Frequency"))
 . S INTERACTIONS(D1,D2,"source")="DIT" ; hardcoded
 . N VAG1 S VAG1=$P(DRUGS(D1,"DINID"),"A",1) ; VA Generic
 . N VAG2 S VAG2=$P(DRUGS(D2,"DINID"),"A",1) ; Ditto
 . S INTERACTIONS(D1,D2,"TITLE")=$$GET1^DIQ(50.6,VAG1,.01)_"/"_$$GET1^DIQ(50.6,VAG2,.01)
 . N EFFTXT S EFFTXT=IXNS(I,"EffLong")_" / Relevance: "_$$REL2TXT(IXNS(I,"Relevance"))_" / Frequency: "_$$FRQ2TXT(IXNS(I,"Frequency"))
 . ; DEBUG ONLY
 . ;  S EFFTXT=EFFTXT_" / VISTA Severity: "_$S($L(VISTASEV):VISTASEV,1:"Interaction not found in VISTA")
 . ; END DEBUG
 . ;
 . S INTERACTIONS(D1,D2,"shortText")=EFFTXT
 . S INTERACTIONS(D1,D2,"disclaimer")="DIT Drug Information Technologies, Inc., claim that the information content and drug interactions measured by any of its medical application software (product) "
 . S INTERACTIONS(D1,D2,"disclaimer")=INTERACTIONS(D1,D2,"disclaimer")_"are intended only to be a source of information for healthcare providers (""Users"") and not to specifically provide medical advice for individual problems."
 . S INTERACTIONS(D1,D2,"monographTitle")=INTERACTIONS(D1,D2,"TITLE")
 . S INTERACTIONS(D1,D2,"severityLevel")=$$SEVTEXT(IXNS(I,"Relevance"),IXNS(I,"Frequency"))
 . M INTERACTIONS(D1,D2,"mechanismOfAction")=IXNS(I,"Mechanism")
 . S INTERACTIONS(D1,D2,"clinicalEffects")=EFFTXT
 . S INTERACTIONS(D1,D2,"preDisposingFactors")="See Patient Management."
 . M INTERACTIONS(D1,D2,"patientManagement")=IXNS(I,"Management")
 . S INTERACTIONS(D1,D2,"discussion")="See other sections."
 ; 
 ; DEBUG
 ; ZWRITE INTERACTIONS R %
 ; DEBUG
 ;
 QUIT
 ;
TEXT(DOCHAND,C) ; Private; Return first line of MXML Text Node
 N T
 D TEXT^MXMLDOM(DOCHAND,C,$NA(T))
 Q:$D(T) @$Q(T)  Q ""
 ;
 ;
 ;
RXN(VUID) ; Private $$; Obtain RxNorm by VUID. Only get RXNS that have NDCs.
 N RXN S RXN=+$$VUI2RXN^C0CRXNLK(VUID) ; Get first RxNorm code
 N NDCS S NDCS=$$RXN2NDC^C0CRXNLK(RXN) ; Convert RXN to NDCs...
 ;
 ; No NDCs? Try getting NDCs for Brand Names, brand after brand
 I NDCS="" D
 . N BRRXNS S BRRXNS=$$GEN2BR^C0CRXNLK(RXN)
 . I BRRXNS="" S RXN="" QUIT
 . N J F J=1:1:$L(BRRXNS,U) S NDCS=$$RXN2NDC^C0CRXNLK($P(BRRXNS,U,J)) Q:$L(NDCS)
 . S RXN=$P(BRRXNS,U,J)
 ;
 QUIT RXN
 ;
NDC(VUID) ; Private $$; Obtain NDC by VUID from RxNorm
 ;
 ; NB: Old code to get NDC from VISTA using VA Product.
 ; N NDCP S NDCP=$O(^PSNDF(50.68,"ANDC",VAP,""),-1)
 ; I 'NDCP S $EC=",U-NO-NDC-FOUND,"
 ; N NDC S NDC=$P(^PSNDF(50.67,NDCP,0),U,2)
 ; S $E(NDC)="" ; Remove first zero -- so damn sneaky!!!
 ; QUIT NDC
 ;
 N RXN S RXN=$$RXN(VUID) ; Get first RxNorm code
 N NDCS S NDCS=$$RXN2NDC^C0CRXNLK(RXN) ; Convert RXN to NDCs...
 ;
 I NDCS="" S $EC=",U-NDC-NOT-FOUND,"
 ;
 ; Choose an NDC at random from all the NDCs we get back.
 N N S N=$L(NDCS,U)
 Q $P(NDCS,U,$R(N)+1)
 ;
 ;
 ;
DITDI(RTN,RXNS) ; Private; Call DIT for drug interactions with these RxNorm codes
 ; RTN - RPC Style return
 ;
 ; Error simulation for Unit Testing.
 ; ZEXCEPT: KBANSIMERR
 I $D(KBANSIMERR) S $EC=",U-SIMULATED-ERROR,"
 ;
 ; Web Service call.
 N RETURN,HEADERS
 D GETGTM(.RETURN,.HEADERS,"DIT DI SERVICE","DIT IXNS",RXNS_"?format=xml")
 ;
 ; UTF BOM; if not removed XML parser will choke!
 N %1 S %1=$O(RETURN(""))
 I $E(RETURN(%1),1,3)=$C(239,187,191) S $E(RETURN(%1),1,3)=""
 ;
 ; DEBUG
 ; ZWRITE RETURN
 ; DEBUG
 ;
 ; Parse XML
 K ^TMP($J,"INPUT XML")
 M ^TMP($J,"INPUT XML")=RETURN
 N DOCHAND S DOCHAND=$$EN^MXMLDOM($NA(^TMP($J,"INPUT XML")),"W")
 K ^TMP($J,"INPUT XML")
 ;
 ; Get interaction nodes using XPATH.
 N RTNPATH
 D XPATH^MXMLPATH(.RTNPATH,DOCHAND,"//InteractionList/Interaction")
 ;
 ; Loop through interaction nodes and pull data from their sub-nodes
 ; CNT = Counter; P = Parent interaction; C = Child interaction
 N CNT S CNT=0
 N P F P=0:0 S P=$O(RTNPATH(P)) Q:'P  D
 . S CNT=CNT+1
 . N C F C=0:0 S C=$$CHILD^MXMLDOM(DOCHAND,P,C) Q:'C  D
 .. S RTN(CNT,$$NAME^MXMLDOM(DOCHAND,C))=$$TEXT(DOCHAND,C)
 ;
 ; Clean handle
 D DELETE^MXMLDOM(DOCHAND)
 QUIT
 ;
DITDIM(ID,MANAGEMENT,MECHANISM) ; Private; DIT Drug interaction monograph
 ; ID - Interaction ID
 ; Management - Output by ref
 ; Mechanism - Output by ref
 ; Web Service call.
 N RTN,HEADERS
 D GETGTM(.RTN,.HEADERS,"DIT DI SERVICE","DIT IXN MONOGRAPH",ID_"?format=xml")
 ;
 ; UTF BOM; if not removed XML parser will choke!
 N %1 S %1=$O(RTN(""))
 I $E(RTN(%1),1,3)=$C(239,187,191) S $E(RTN(%1),1,3)=""
 ;
 ; DEBUG
 ; ZWRITE RTN
 ; DEBUG
 ; Parse XML
 K ^TMP($J,"INPUT XML")
 M ^TMP($J,"INPUT XML")=RTN
 N DOCHAND S DOCHAND=$$EN^MXMLDOM($NA(^TMP($J,"INPUT XML")),"W")
 K ^TMP($J,"INPUT XML")
 ;
 ; Pull Management node
 N MGMTNODE S MGMTNODE=$$XPATH^MXMLPATH(,DOCHAND,"//Management/d4p1:string")
 I 'MGMTNODE S MANAGEMENT=""
 E  D TEXT^MXMLDOM(DOCHAND,MGMTNODE,$NA(MANAGEMENT))
 ; . N I F I=0:0 S I=$O(MANAGEMENT(I)) Q:'I  S MANAGEMENT=$G(MANAGEMENT)_MANAGEMENT(I) K MANAGEMENT(I)
 ;
 ; Pull Mechanism node
 N MECHNODE S MECHNODE=$$XPATH^MXMLPATH(,DOCHAND,"//Mechanism/d4p1:string")
 I 'MECHNODE S MECHANISM=""
 E  D TEXT^MXMLDOM(DOCHAND,MECHNODE,$NA(MECHANISM))
 ; . N I F I=0:0 S I=$O(MECHANISM(I)) Q:'I  S MECHANISM=$G(MECHANISM)_MECHANISM(I) K MECHANISM(I)
 QUIT
 ;
DITINFO(DRUGS) ; Private; Call DIT for info with these RxNorms's
 ;    ---> to populate the SYN10 codes.
 ;    ---> (also a new addition) to populate the drug classes.
 ; If ixns call returns rxn's, we don't need this call anymore.
 ; DRUGS - Input and Output!
 ;
 ; For each drug...
 N I F I=0:0 S I=$O(DRUGS(I)) Q:'I  D
 . N RXN S RXN=DRUGS(I,"RXN")
 . N RTN,HEADERS
 . D GETGTM(.RTN,.HEADERS,"DIT DI SERVICE","DIT INFO",RXN_"?format=xml")
 . ;
 . ; UTF BOM; if not removed XML parser will choke!
 . N %1 S %1=$O(RTN(""))
 . I $E(RTN(%1),1,3)=$C(239,187,191) S $E(RTN(%1),1,3)=""
 . ;
 . ; Parse XML
 . K ^TMP($J,"INPUT XML")
 . M ^TMP($J,"INPUT XML")=RTN
 . N DOCHAND S DOCHAND=$$EN^MXMLDOM($NA(^TMP($J,"INPUT XML")),"W")
 . K ^TMP($J,"INPUT XML")
 . ;
 . ; Extract Syn10 codes; N = Node
 . N N S N=$$XPATH^MXMLPATH(,DOCHAND,"/DrugsResponse/DrugList/Drug/SynCode10")
 . N SYN10 S SYN10=$$TEXT(DOCHAND,N)
 . S DRUGS(I,"SYN10")=SYN10
 . S DRUGS("SYN10",SYN10,I)="" ; Index for looking up the drugs in the array.
 . ;
 . ; Extract Therapy class; N = Node
 . N N S N=$$XPATH^MXMLPATH(,DOCHAND,"/DrugsResponse/DrugList/Drug/TherapyClass")
 . N T D TEXT^MXMLDOM(DOCHAND,N,$NA(T))
 . N J,DITCL F J=0:0 S J=$O(T(J)) Q:'J  S DITCL=$G(DITCL)_T(J) ; DITCL = DIT Class
 . S DRUGS(I,"DITCL")=DITCL
 . ;
 . D DELETE^MXMLDOM(DOCHAND)
 QUIT
 ;
SEVERITY(REL,FREQ) ; $$ - Public ; DIT Criticality conversion to VISTA
 ;
 ; NB: CAREFUL HERE. THIS CONTROLS WHAT THE VISTA USER WILL SEE.
 ; ANYTHING NOT C OR S WILL NOT SHOW UP FOR THE USER.
 ; MOST CPRS USERS WILL NOT SEE S.
 ; PHARMACISTAS ALWAYS SEE S.
 ; In general: RED = Critical; YELLOW = Significant
 ; RED/YELLOW classification comes from DIT Traffic Lights Customer Table.
 ;
 ; Input: By Value: Relvance and Frequency
 ;
 ; RETURN:
 ; C = Critical
 ; S = Significant
 ; U = Unsignificant
 ;
 I REL=5 Q "C" ; Red
 I REL=4&(678[FREQ) Q "C" ; Red
 I REL=4&(54321[FREQ) Q "S" ; Yellow
 Q "U"
 ;
REL2TXT(REL) ; $$ - Public ; DIT Relevance Number to Relevance Text
 I REL=1 Q "No Interaction"
 I REL=2 Q "No Interaction"
 I REL=3 Q "Minor"
 I REL=4 Q "Important"
 I REL=5 Q "Dangerous"
 S $EC=",U-NO-RELEVANCE-TRANSLATION-FOUND,"
 Q ""
 ;
FRQ2TXT(FRQ) ; $$ - Public ; DIT Frequency Number to Frequency Text
 I 1234[FRQ Q "Possible"
 I FRQ=5 Q "Frequent"
 I FRQ=6 Q "Probable"
 I FRQ=7 Q "Very Frequent"
 I FRQ=8 Q "Sure"
 S $EC=",U-NO-FREQUENCY-TRANSLATION-FOUND,"
 Q ""
 ;
SEVTEXT(REL,FREQ) ; $$ - Public ; DIT drug interaction severity text
 ; Text taken from Traffic Lights Customer Table (dangerous in 5 replaced w/ CRITICAL).
 I REL=5 Q "There is a CRITICAL drug interaction which should be avoided."
 I REL=4,876[FREQ Q "There is an important drug interaction which should be avoided."
 I REL=4,FREQ=5 Q "There may be an important drug interaction which should be avoided."
 I REL=4,1234[FREQ Q "There may be a drug interaction, which are in most cases not relevant or normally of minor importance."
 I REL=3 Q "There may be a drug interaction, which is normally of minor importance."
 Q "There is no drug interaction"
 ;
CLEAN(IXNS,DRUGS,PROS) ; Private Procedure; Clean Interactions
 ; Pass IXNS and DRUGS by reference.
 ; IXNS modified in place and is the return as well.
 ; 1. Remove unimportant interactions
 ; 2. Remove interactions between Med Profile drugs
 ; 3. Remove interactions between No-interaction drugs (50.68,23)
 ;
 ; PROS = 1 or 0. Is this a prospective only check?
 ;
 ; 1. Remove unimportant interactions
 N I F I=0:0 S I=$O(IXNS(I)) Q:'I  D
 . ; Keep this!! No freq/severity are supplied with dups; otherwise we will get "U"
 . I $$UP^XLFSTR(IXNS(I,"EffLong"))["DUPLICATE THERAPY" QUIT
 . I $$SEVERITY(IXNS(I,"Relevance"),IXNS(I,"Frequency"))="U" KILL IXNS(I)
 ;
 ; 3. Remove interactions between No-interaction drugs (50.68,23)
 N I F I=0:0 S I=$O(IXNS(I)) Q:'I  D
 . N SYN1 S SYN1=IXNS(I,"SynCcode1")
 . N SYN2 S SYN2=IXNS(I,"SynCcode2")
 . N D1 S D1=$O(DRUGS("SYN10",SYN1,""))
 . N D2 S D2=$O(DRUGS("SYN10",SYN2,""))
 . N D1X,D2X ; Exclude interaction?
 . S D1X=DRUGS(D1,"NOIXN")
 . S D2X=DRUGS(D2,"NOIXN")
 . I (D1X!D2X)&($$UP^XLFSTR(IXNS(I,"EffLong"))'["DUPLICATE THERAPY") K IXNS(I)
 ;
 ; If the check isn't prospective only (i.e. entire profile), 
 ; then display all interactions. In our case, don't remove profile drug
 ; interactions
 I 'PROS QUIT
 ;
 ; 2. Remove profile drug interactions/duplications with each other
 N I F I=0:0 S I=$O(IXNS(I)) Q:'I  D
 . N SYN1 S SYN1=IXNS(I,"SynCcode1")
 . N SYN2 S SYN2=IXNS(I,"SynCcode2")
 . N D1 S D1=$O(DRUGS("SYN10",SYN1,""))
 . N D2 S D2=$O(DRUGS("SYN10",SYN2,""))
 . ;
 . N D1M,D2M ; Med Profile Drug (Boolean)
 . S D1M=''$D(DRUGS("M",D1))
 . S D2M=''$D(DRUGS("M",D2))
 . I D1M&D2M K IXNS(I)
 ;
 QUIT
 ;
GETGTM(RETURN,HEADERS,SERVER,SERVICE,PATH) ; PEP -- GET on GT.M using many fileses
 ; RETURN  - Output
 ; HEADERS - Output
 ; SERVER  - NAME in WEB SERVER file
 ; SERVICE - NAME in WEB SERVICE file
 ; PATH    - PATH to append to the
 ;
 ;
 ; Get Server IEN
 N SERVERIEN S SERVERIEN=+$ORDER(^XOB(18.12,"B",SERVER,0)) ; per getWebServerId
 I 'SERVERIEN S %XOBWERR=186005_U_SERVER,$EC=",UXOBW," ;##class(xobw.error.DialogError).forceError(186005_"^"_webServerName)
 ;
 ; Get Service IEN
 N SERVICEIEN S SERVICEIEN=+$order(^XOB(18.02,"B",SERVICE,0)) ; per getWebServiceId(webServiceName)
 I 'SERVICEIEN S %XOBWERR=186006_U_SERVICE,$EC=",UXOBW," ; #class(xobw.error.DialogError).forceError(186006_"^"_webServiceName)
 ;
 ; Service Type must be REST
 I $P(^XOB(18.02,SERVICEIEN,0),U,2)'=2 S %XOBWERR=186007,$EC=",UXOBW," ; forceError(186007)
 ;
 ; Is Web Server disabled?
 N Z S Z=^XOB(18.12,SERVERIEN,0) ; Zero node
 I '$P(Z,U,6) S %XOBWERR=186002_U_$P(Z,U),$EC=",UXOBW,"  ; ##class(xobw.error.DialogError).forceError(186002_"^"_webServer.name)
 ;
 ; Is web service authorized? per getAuthorizedWebServiceId
 N SUBSERVICEIEN S SUBSERVICEIEN=$O(^XOB(18.12,SERVERIEN,100,"B",SERVICEIEN,""))
 I 'SUBSERVICEIEN S %XOBWERR=186003_U_$P(^XOB(18.02,SERVICEIEN,0),U)_U_$P(Z,U),$EC=",UXOBW," ;forceError(186003_"^"_..webServiceMetadata.name_"^"_webServer.name)
 ;
 ; Is the service disabled at the server level?
 N SN S SN=^XOB(18.12,SERVERIEN,100,SUBSERVICEIEN,0) ; SN = service node
 I '$P(SN,U,6) S %XOBWERR=186004_U_$P(^XOB(18.02,SERVICEIEN,0),U)_U_$P(Z,U),$EC=",UXOBW" ; forceError(186004_"^"_..webServiceMetadata.name_"^"_webServer.name)
 ;
 ; Get Username and password if present
 ; TODO: Not implemented by Sam. Easy to implement.
 ; Note: Code below different than Cache logic. Will only get un/pw if
 ; it's Yes. Cache code gets it if Yes or empty.
 ; I $G(^XOB(18.12,SERVERIEN,1)) D
 ; . N UN S UN=^XOB(18.12,SERVERIEN,200)
 ; . N PW S PW=$$DECRYP^XOBVPWD($G(^XOB(18.12,SERVERIEN,300)))
 ; ;
 ; Then
 ; curl un:pw@url
 ;
 N FQDN S FQDN=$P(Z,U,4) ; IP or Domain name
 N PORT S PORT=$P(Z,U,3) ; Http Port
 N TO S TO=$P(Z,U,7) ; HTTP Timeout
 N ISTLS S ISTLS=$P($G(^XOB(18.12,SERVERIEN,3)),U) ; Is SSL/TLS on?
 I ISTLS S PORT=$P($G(^XOB(18.12,SERVERIEN,3)),U,3) ; replace port
 N CONTEXT S CONTEXT=$G(^XOB(18.02,SERVICEIEN,200)) ; really, just the path on the server.
 ;
 ; Create URL
 N URL S URL="http"_$S(ISTLS:"s",1:"")_"://"_FQDN_":"_PORT_CONTEXT_PATH
 ;
 ; Action
 D %^%WC(.RETURN,"GET",URL,,,TO,.HEADERS)
 ;
 ; Check status code to be 200.
 I HEADERS("STATUS")'=200 S %XOBWERR=HEADERS("STATUS"),$EC=",UXOBWHTTP,"
 QUIT
