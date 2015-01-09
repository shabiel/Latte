PSSHTTP ;WOIFO/AV - REENGINERING Sends XML Request to PEPS via HWSC ;2013-08-06  11:18 AM
 ;;1.0;PHARMACY DATA MANAGEMENT;**136,13100000**;9/30/97
 ;
 ; @author  - Alex Vazquez, Chris Flegel, Timothy Sabat, S Gordon
 ; @date    - September 19, 2007
 ; @version - 1.0
 ;
 ; Modifications for Mocha bypass by VEN/SMH (*13100000)
 ;
 QUIT
 ;;
PEPSPOST(DOCHAND,XML) ;
 ; @DESC Sends an HTTP request to PEPS as a POST
 ;
 ; @DOCHAND Handle to XML document
 ; @XML XML request as string
 ;
 ; @RETURNS A handle to response XML document
 ;          1 for success, 0 for failure
 ;
 ;DEBUG
 ;ZWRITE XML
 ;R %
 ;DEBUG
 ;
 ; VEN/SMH - MOCHA External Interface replacement
 ;
 ; Grab Input XML and parse.
 K ^TMP($J,"INPUT XML")
 M ^TMP($J,"INPUT XML",1)=XML
 N DOCHAND2 S DOCHAND2=$$EN^MXMLDOM($NA(^TMP($J,"INPUT XML")),"W")
 K ^TMP($J,"INPUT XML")
 ;
 ; Send parsed XML to be analyzed for drug checks. Response XML produced
 ; will be found in RESULT.
 ;
 N RESULT
 D EN^KBANLATT(.RESULT,DOCHAND2)
 ;
 ; Remove parsed input XML.
 D DELETE^MXMLDOM(DOCHAND2)
 ;
 K RESULT("mime") ; Remove mime thingy intended for the web server.
 ;
 ;DEBUG
 ;ZWRITE RESULT
 ;R %
 ;DEBUG
 ;
 ; Parse output XML and return Handle in DOCHAND (passed here by ref).
 K ^TMP($J,"OUTPUT XML")
 M ^TMP($J,"OUTPUT XML")=RESULT
 ; Parse the XML (W = No DTD supplied)
 SET DOCHAND=$$EN^MXMLDOM($NA(^TMP($J,"OUTPUT XML")),"W")
 K ^TMP($J,"OUTPUT XML")
 ;
 IF DOCHAND<1 QUIT 0 ; XML Parsing failure
 ;
 ; Success!
 QUIT 1
 ; /END VEN/SMH - MOCHA External Interface replacement
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;
 ;
 NEW PSS,PSSERR,$ETRAP,$ESTACK
 ;
 ; Set error trap
 SET $ETRAP="DO ERROR^PSSHTTP"
 ;
 SET PSS("server")="PEPS"
 SET PSS("webserviceName")="ORDER_CHECKS"
 SET PSS("path")="ordercheck"
 ;
 SET PSS("parameterName")="xmlRequest"
 SET PSS("parameterValue")=XML
 ;
 ; Get instance of client REST request object
 SET PSS("restObject")=$$GETREST^XOBWLIB(PSS("webserviceName"),PSS("server"))
 IF $DATA(^TMP($JOB,"OUT","EXCEPTION"))>0 QUIT 0
 ;
 ; Insert XML as parameter
 DO PSS("restObject").InsertFormData(PSS("parameterName"),PSS("parameterValue"))
 IF $DATA(^TMP($JOB,"OUT","EXCEPTION"))>0 QUIT 0
 ;
 ; Execute HTTP Post method
 SET PSS("postResult")=$$POST^XOBWLIB(PSS("restObject"),PSS("path"),.PSSERR)
 IF $DATA(^TMP($JOB,"OUT","EXCEPTION"))>0 QUIT 0
 ;
 DO:PSS("postResult")
 . SET PSS("result")=##class(gov.va.med.pre.ws.XMLHandler).getHandleToXmlDoc(PSS("restObject").HttpResponse.Data, .DOCHAND)
 . QUIT
 ;
 DO:'PSS("postResult")
 . SET ^TMP($JOB,"OUT","EXCEPTION")="Unable to make http request."
 . SET PSS("result")=0
 . QUIT
 ;
 QUIT PSS("result")
 ;;
ERROR ;
 ; @DESC Handles error during request to PEPS via webservice.
 ;
 ; Depends on GLOBAL variable PSSERR to be set in previous call.
 ;
 ; @RETURNS Nothing. Value store in global.
 ;
 NEW ERRARRAY
 ;
 ; Get error object from Error Object Factory
 IF $GET(PSSERR)="" SET PSSERR=$$EOFAC^XOBWLIB()
 ; Store the error object in the error array
 DO ERR2ARR^XOBWLIB(PSSERR,.ERRARRAY)
 ;
 ; Parse out the error text and store in global
 SET ^TMP($JOB,"OUT","EXCEPTION")=$$GETTEXT(.ERRARRAY)
 ;
 ; Set ecode to empty to return to calling function
 SET $ECODE=""
 ;
 QUIT
 ;;
GETTEXT(ERRARRAY) ;
 ; @DESC Gets the error text from the array
 ;
 ; @ERRARRAY Error array stores error in format defined by web service product.
 ;
 ; @RETURNS Error info as a single string
 ;
 NEW PSS
 ;
 ; Loop through the text subscript of error array and concatenate
 SET PSS("errorText")=""
 SET PSS("I")=""
 FOR  SET PSS("I")=$ORDER(ERRARRAY("text",PSS("I"))) QUIT:PSS("I")=""  DO
 . SET PSS("errorText")=PSS("errorText")_ERRARRAY("text",PSS("I"))
 . QUIT
 ;
 QUIT PSS("errorText")
 ;;
