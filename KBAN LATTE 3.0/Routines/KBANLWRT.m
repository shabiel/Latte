KBANLWRT ; VEN/SMH - KBAN Latte Response Writer ;2015-01-09  1:42 PM
 ;;3.0;KBAN LATTE;;
 ; (c) Sam Habiel 2013.
 ;
 ; Usage is granted to the user under accompanying license.
 ; If you can't find the license, you are not allowed to use the software.
 ;
 ; All entry points here are private
 ;
SENDPING(RESULT) ; Private; Send a Ping Reply; Internal to this routine.
 ; RESULT - Return array for XML.
 ;
 ; See GTDBINFO^PSSHRQ2O for parsing logic for pings
 ; <?xml version="1.0" encoding="ASCII" standalone="yes"?>
 ; <PEPSResponse xsi:schemaLocation="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 ;     <Header pingOnly="true">
 ;         <Time value="3130514"/>
 ;         <MServer namespace="" uci="" ip="" serverName="" stationNumber="500"></MServer>
 ;         <MUser userName="PROGRAMMER,ONE" duz="1" jobNumber="7137"></MUser>
 ;         <PEPSVersion difIssueDate="20130324" difBuildVersion="1.0" difDbVersion="3.2"></PEPSVersion>
 ;     </Header>
 ; </PEPSResponse>
 ;
 D PUT^MXMLBLD(.RESULT,$$XMLHDR^MXMLUTL)
 N %
 S %("xsi:schemaLocation")=""
 S %("xmlns:xsi")="http://www.w3.org/2001/XMLSchema-instance"
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("PEPSResponse",.%,,0))
 ;
 N % S %("pingOnly")="true"
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("Header",.%,,0))
 N % S %("value")=DT
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("Time",.%))
 D PEPSVER(.RESULT)
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/Header"))
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/PEPSResponse"))
 QUIT
 ;
PEPSVER(RESULT) ; Private. Write PEPSVersion tag. Shared among several EPs.
 N REVDATE S REVDATE=1700+$E(DT,1,3)_$E(DT,4,5)_$E(DT,6,7)
 N %
 S %("difIssueDate")=REVDATE
 S %("difBuildVersion")="VISTA"
 S %("difDbVersion")="VISTA"
 S %("customIssueDate")="VISTA"
 S %("customBuildVersion")="VISTA"
 S %("customDbVersion")="VISTA"
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("PEPSVersion",.%))
 QUIT
 ;
RESPOND(RESULT,DOCHAND,INTERACTIONS,DUPCLASS,DRUGSNOTCHECKED,DRUGDRUGCHECK,DRUGTHERAPYCHECK,DRUGDOSECHECK) ; XML Response Writer; Private
 ; Output:
 ; - .RESULT -> Return array for XML
 ;
 ; Input:
 ; - DOCHAND -> MXML Original Input document Handle
 ; - .INTERACTIONS -> Array of Interactions. May be empty.
 ; - .DUPCLASS -> Array of duplicate classes. May be empty.
 ; - .DRUGSNOTCHECKED -> Array of drugs not checked. May be empty.
 ; - DRUGDRUGCHECK -> Boolean. Was a drug-drug check requested?
 ; - DRUGTHERAPYCHECK -> Boolean. Was a duplicate drug class check requested?
 ; - DRUGDOSECHECK -> Boolean. Was a dosing check requested?
 ;
 ; Outline:
 ; - Write <?xml
 ; - Open <PEPSResponse>, Write <Header> block, open <Body>, <drugCheck>
 ; - Write specific sections (Drug-Drug, Drug Therapy Duplication, Dosage checks)
 ; - Write </drugCheck>, </Body>, </PEPSResponse>
 ;
 D PUT^MXMLBLD(.RESULT,$$XMLHDR^MXMLUTL) ; <?xml etc...
 ;
 N %
 S %("xsi:schemaLocation")="gov/va/med/pharmacy/peps/external/common/preencapsulation/vo/drug/check/response drugCheckSchemaOutput.xsd"
 S %("xmlns:xsi")="http://www.w3.org/2001/XMLSchema-instance"
 S %("xmlns")="gov/va/med/pharmacy/peps/external/common/preencapsulation/vo/drug/check/response"
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("PEPSResponse",.%,,0)) ; <PEPSResponse ...
 ;
 D HEADER(.RESULT)
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("Body",,,0)) ; <Body>
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugCheck",,,0)) ; <drugCheck>
 ;
 ;
 D:$D(DRUGSNOTCHECKED) RITEDNCK(.RESULT,.DRUGSNOTCHECKED,DOCHAND) ; Drugs not checked.
 ;
 ;
 D:DRUGDRUGCHECK RITEDGDG(.RESULT,.INTERACTIONS,DOCHAND) ; Drug-Drug Interaction
 D:DRUGTHERAPYCHECK RITEDUP(.RESULT,.DUPCLASS,DOCHAND) ; Duplicate Therapy
 D:DRUGDOSECHECK RITEDOSE(.RESULT) ; Drug-dose check
 ;
 ;
 ; Close
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/drugCheck"))
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/Body"))
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/PEPSResponse"))
 QUIT
 ;
HEADER(RESULT) ; Private; Create XML Header Block.
 ;   <Header>
 ;       <Time value="0845"/>
 ;       <MServer namespace="VISTA" uci="text" ip="127.0.000.1"
 ;           serverName="Server Name" stationNumber="45"/>
 ;       <MUser userName="user" duz="88660079" jobNumber="1001"/>
 ;       <PEPSVersion difIssueDate="20091002" difBuildVersion="6" difDbVersion="3.2"/>
 ;   </Header>
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("Header",,,0)) ; <Header>
 ;
 N % S %("value")=$$NOW^XLFDT() D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("Time",.%)) ; <Time value="0845"/>
 ;
 D  ; <MServer namespace="VISTA" uci="text" ip="127.0.0.1" serverName="Server Name" stationNumber="45" />
 . N Y D GETENV^%ZOSV
 . N %
 . S %("namespace")=$P(Y,U)
 . S %("uci")=$P(Y,U)
 . S %("ip")="127.0.0.1"
 . S %("serverName")=$P(Y,U,3)
 . S %("stationNumber")=$P($$SITE^VASITE(),U,3)
 . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("MServer",.%))
 ;
 D  ; <MUser userName="user" duz="88660079" jobNumber="1001"/>
 . N %
 . S %("duz")=$S($G(DUZ):DUZ,1:.5)
 . S %("userName")=$P(^VA(200,%("duz"),0),U)
 . S %("jobNumber")=$JOB
 . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("MUser",.%))
 ;
 D PEPSVER(.RESULT) ; <PEPSVersion difIssueDate="20091002" difBuildVersion="6" difDbVersion="3.2"/>
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/Header"))
 QUIT
 ;
 ;
 ;
RITEDGDG(RESULT,INTERACTIONS,DOCHAND) ; Private; Write the XML Response for Drug Interaction part
 ; Output (appending):
 ; - .RESULT
 ;
 ; Input:
 ; - INTERACTIONS
 ; - DOCHAND
 ;
 ; See above for descriptions
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugDrugChecks",,,0)) ; <drugDrugChecks>
 ;
 ; D1=Drug 1 and D2=Drug 2
 N D1 S D1=0 F  S D1=$O(INTERACTIONS(D1)) Q:'D1  D
 . N D2 S D2=0 F  S D2=$O(INTERACTIONS(D1,D2)) Q:'D2  D
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugDrugCheck",,,0)) ; <drugDrugCheck>
 . . ;
 . . ; Id tag not needed.
 . . ; Source
 . . I $D(INTERACTIONS(D1,D2,"source")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("source",,$$ESC(INTERACTIONS(D1,D2,"source"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("source",,"VISTA")) ; <source>VISTA</source>; also not needed but I want it.
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("interactedDrugList",,,0)) ; <interactedDrugList>
 . . ;
 . . D  ; <drug orderNumber="Z;2;Prospect" ien="455" gcnSeqNo="25485"/>
 . . . N %
 . . . S %("orderNumber")=$$VALUE^MXMLDOM(DOCHAND,D1,"orderNumber")
 . . . S %("ien")=$$VALUE^MXMLDOM(DOCHAND,D1,"ien")
 . . . S %("vuid")=$$VALUE^MXMLDOM(DOCHAND,D1,"vuid")
 . . . S %("drugName")=$$VALUE^MXMLDOM(DOCHAND,D1,"drugName")
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drug",.%))
 . . ;
 . . D  ; Ditto
 . . . N %
 . . . S %("orderNumber")=$$VALUE^MXMLDOM(DOCHAND,D2,"orderNumber")
 . . . S %("ien")=$$VALUE^MXMLDOM(DOCHAND,D2,"ien")
 . . . S %("vuid")=$$VALUE^MXMLDOM(DOCHAND,D2,"vuid")
 . . . S %("drugName")=$$VALUE^MXMLDOM(DOCHAND,D2,"drugName")
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drug",.%))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/interactedDrugList")) ; </interactedDrugList>
 . . ;
 . . N SEVTXT S SEVTXT=$S(INTERACTIONS(D1,D2)="C":"Contraindicated Drug Combination",1:"Severe Interaction")
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("severity",,SEVTXT))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("interaction",,$$ESC(INTERACTIONS(D1,D2,"TITLE"))))
 . . ;
 . . I $D(INTERACTIONS(D1,D2,"shortText")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("shortText",,$$ESC(INTERACTIONS(D1,D2,"shortText"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("shortText",,"More information not available in this interface"))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("professionalMonograph",,,0))
 . . ;
 . . I $D(INTERACTIONS(D1,D2,"disclaimer")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("disclaimer",,$$ESC(INTERACTIONS(D1,D2,"disclaimer"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("disclaimer",,"Disclaimer not available in this interface"))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("monographTitle",,"MONOGRAPH TITLE:  "_$$ESC(INTERACTIONS(D1,D2,"TITLE"))))
 . . ;
 . . N SEVTXT2
 . . I $D(INTERACTIONS(D1,D2,"severityLevel")) S SEVTXT2="SEVERITY LEVEL:  "_$$ESC(INTERACTIONS(D1,D2,"severityLevel"))
 . . E  D
 . . . I INTERACTIONS(D1,D2)="C" S SEVTXT2="SEVERITY LEVEL:  1-Contraindicated Drug Combination: This drug combination is contraindicated and generally should not be dispensed or administered to the same patient."
 . . . E  S SEVTXT2="SEVERITY LEVEL:  2-Severe Interaction: Action is required to reduce the risk of severe adverse interaction."
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("severityLevel",,SEVTXT2)) ; Per PSODDPR3; Must have SEVERITY LEVEL
 . . ;
 . . I $D(INTERACTIONS(D1,D2,"mechanismOfAction")) D
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("mechanismOfAction",,,0))
 . . . D PUT^MXMLBLD(.RESULT,"MECHANSIM OF ACTION:  ")
 . . . D:($D(INTERACTIONS(D1,D2,"mechanismOfAction"))#2) PUT^MXMLBLD(.RESULT,$$ESC(INTERACTIONS(D1,D2,"mechanismOfAction")))
 . . . N % S %="" F  S %=$O(INTERACTIONS(D1,D2,"mechanismOfAction",%)) Q:'%  D PUT^MXMLBLD(.RESULT,$$ESC(INTERACTIONS(D1,D2,"mechanismOfAction",%)))
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/mechanismOfAction"))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("mechanismOfAction",,"MECHANISM OF ACTION:  Mechanism of Action not available in this interface"))
 . . ;
 . . I $D(INTERACTIONS(D1,D2,"clinicalEffects")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("clinicalEffects",,"CLINICAL EFFECTS:  "_$$ESC(INTERACTIONS(D1,D2,"clinicalEffects"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("clinicalEffects",,"CLINICAL EFFECTS:  Clinical Effects not available in this interface"))
 . . ;
 . . I $D(INTERACTIONS(D1,D2,"preDisposingFactors")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("preDisposingFactors",,"PREDISPOSING FACTORS:  "_$$ESC(INTERACTIONS(D1,D2,"preDisposingFactors"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("preDisposingFactors",,"PREDISPOSING FACTORS:  Pre-Disposing Factors not available in this interface"))
 . . ;
 . . I $D(INTERACTIONS(D1,D2,"patientManagement")) D
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("patientManagement",,,0))
 . . . D PUT^MXMLBLD(.RESULT,"PATIENT MANAGEMENT:  ")
 . . . D:($D(INTERACTIONS(D1,D2,"patientManagement"))#2) PUT^MXMLBLD(.RESULT,$$ESC(INTERACTIONS(D1,D2,"patientManagement")))
 . . . N % S %="" F  S %=$O(INTERACTIONS(D1,D2,"patientManagement",%)) Q:'%  D PUT^MXMLBLD(.RESULT,$$ESC(INTERACTIONS(D1,D2,"patientManagement",%)))
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/patientManagement"))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("patientManagement",,"PATIENT MANAGEMENT:  Patient Management recommendations not available in this interface"))
 . . ;
 . . I $D(INTERACTIONS(D1,D2,"discussion")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("discussion",,"DISCUSSION:  "_$$ESC(INTERACTIONS(D1,D2,"discussion"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("discussion",,"DISCUSSION:  Further discussion not available in this interface"))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/professionalMonograph"))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/drugDrugCheck"))
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/drugDrugChecks"))
 QUIT
 ;
RITEDUP(RESULT,DUPCLASS,DOCHAND) ; Private Proc; Write Duplicate Therapy
 ; Output (appending):
 ; - .RESULT
 ;
 ; Input:
 ; - DUPCLASS
 ; - DOCHAND
 ;
 ; See above for descriptions
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugTherapyChecks",,,0)) ; <drugTherapyChecks>
 ;
 ; D1=Drug 1 and D2=Drug 2
 N D1 S D1=0 F  S D1=$O(DUPCLASS(D1)) Q:'D1  D
 . N D2 S D2=0 F  S D2=$O(DUPCLASS(D1,D2)) Q:'D2  D
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugTherapyCheck",,,0)) ; <drugTherapyCheck>
 . . ;
 . . ; Id tag not needed.
 . . ; Source
 . . I $D(DUPCLASS(D1,D2,"source")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("source",,$$ESC(DUPCLASS(D1,D2,"source"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("source",,"VISTA")) ; <source>VISTA</source>; also not needed but I want it.
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("interactedDrugList",,,0)) ; <interactedDrugList>
 . . ;
 . . D  ; <drug orderNumber="Z;2;Prospect" ien="455" gcnSeqNo="25485"/>
 . . . N %
 . . . S %("orderNumber")=$$VALUE^MXMLDOM(DOCHAND,D1,"orderNumber")
 . . . S %("ien")=$$VALUE^MXMLDOM(DOCHAND,D1,"ien")
 . . . S %("vuid")=$$VALUE^MXMLDOM(DOCHAND,D1,"vuid")
 . . . S %("drugName")=$$VALUE^MXMLDOM(DOCHAND,D1,"drugName")
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drug",.%))
 . . ;
 . . D  ; Ditto
 . . . N %
 . . . S %("orderNumber")=$$VALUE^MXMLDOM(DOCHAND,D2,"orderNumber")
 . . . S %("ien")=$$VALUE^MXMLDOM(DOCHAND,D2,"ien")
 . . . S %("vuid")=$$VALUE^MXMLDOM(DOCHAND,D2,"vuid")
 . . . S %("drugName")=$$VALUE^MXMLDOM(DOCHAND,D2,"drugName")
 . . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drug",.%))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/interactedDrugList")) ; </interactedDrugList>
 . . ;
 . . ; Fill classification, duplicateAllowance, shortText
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("classification",,$$ESC(DUPCLASS(D1,D2))))
 . . ;
 . . I $D(DUPCLASS(D1,D2,"duplicateAllowance")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("duplicateAllowance",,$$ESC(DUPCLASS(D1,D2,"duplicateAllowance"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("duplicateAllowance",,0))
 . . ;
 . . I $D(DUPCLASS(D1,D2,"shortText")) D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("shortText",,$$ESC(DUPCLASS(D1,D2,"shortText"))))
 . . E  D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("shortText",,"More information not available in this interface"))
 . . ;
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/drugTherapyCheck")) ; Close this check
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/drugTherapyChecks"))
 QUIT
 ;
RITEDOSE(RESULT) ; Private Proc; Write dose - not implmemented in this interface
 ; Send back a correct but empty response.
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugDoseChecks"))
 QUIT
 ;
RITEDNCK(RESULT,DRUGSNOTCHECKED,DOCHAND) ; Private Proc; Write drugs not checked...
 ; Input:
 ; .RESULT - RPC style return array
 ; .DRUGSNOTCHECKED - List of drugs where checks couldn't be performed
 ; DOCHAND - Original PEPS message MXML Document handle
 ;
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugsNotChecked",,,0)) ; Open tag
 N D F D=0:0 S D=$O(DRUGSNOTCHECKED(D)) Q:'D  D
 . N % S %("status")="vuidMissingOrInvalid"
 . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drugNotChecked",.%,,0)) ; Open tag
 . ; Punch in the drug:
 . D  ; <drug orderNumber="Z;2;Prospect" ien="455" gcnSeqNo="25485"/>
 . . N %
 . . S %("orderNumber")=$$VALUE^MXMLDOM(DOCHAND,D,"orderNumber")
 . . S %("ien")=$$VALUE^MXMLDOM(DOCHAND,D,"ien")
 . . S %("vuid")=$$VALUE^MXMLDOM(DOCHAND,D,"vuid")
 . . S %("drugName")=$$VALUE^MXMLDOM(DOCHAND,D,"drugName")
 . . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("drug",.%))
 . D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/drugNotChecked")) ; Close tag
 D PUT^MXMLBLD(.RESULT,$$MKTAG^MXMLBLD("/drugsNotChecked")) ; Close tag
 QUIT
ESC(STR) ; Escape string for XML
 Q $$SYMENC^MXMLUTL(STR)
