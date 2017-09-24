C0DIMP ; VEN/SMH - Import French Drug Interactions;2017-09-24  12:00 PM
 ;;4.0;LATTE;;
 ;
 ; Instructions:
 ; - Clone the osdi repo from https://github.com/glilly/osdi
 ; - d engrp^C0DIMP("path/to/classes_xml folder")
 ; - d enDrug^C0DIMP("path/to/tables_xml folder")
 ; - d popVUID^C0DIMP
 ; - d crIndexFile^C0DIMP
 ;
engrp(path) ; [Public] - Import Entry Point for Groups
 ; rm file data
 n z s z=^C0D(176.201,0)
 s $p(z,"^",3,4)=""
 k ^C0D(176.201)
 s ^C0D(176.201,0)=z
 ;
 N % S %=$$FILEINIT^XTMLOG("C0DIMP")
 n a s a("*.xml")=""
 n files
 n % s %=$$LIST^%ZISH(path,$na(a),$na(files))
 d DEBUG^XTMLOG("Directory is "_path)
 ; D SAVEARR^XTMLOG(files)
 n file s file=""
 f  s file=$o(files(file)) q:file=""  d grpFile(path,file)
 d ENDLOG^XTMLOG("C0DIMP")
 quit
 ;
grpFile(path,file) ; [Private] - Process each group file. Called ONLY by engrp.
 ;
 n fda,err
 ;
 n h s h=$$EN^MXMLDOM(path_"/"_file,"W")
 d INFO^XTMLOG("XML Handle is "_h_"; file is "_file)
 ;
 n sourceFile
 n sourceFileNode s sourceFileNode=$$XPATH^MXMLPATH(,h,"//SOURCE_FILE")
 d TEXT^MXMLDOM(h,sourceFileNode,$na(sourceFile))
 s sourceFile=sourceFile(1)
 k sourceFile(1)
 d INFO^XTMLOG("Source file is "_sourceFile)
 ;
 n att s att=""
 f  s att=$$ATTRIB^MXMLDOM(h,1,att) q:att=""  d
 . s attval=$$VALUE^MXMLDOM(h,1,att)
 . d DEBUG^XTMLOG("attrib "_att_"="_attval)
 . i att="name" s fda(176.201,"+1,",.01)=$$TRIM^XLFSTR(attval)
 . i att="code" s fda(176.201,"+1,",.02)=$$TRIM^XLFSTR(attval)
 ;
 s fda(176.201,"+1,",99)=$$TRIM^XLFSTR(sourceFile)
 ;
 n drgcnt s drgcnt=1
 n atccnt s atccnt=2000
 n c s c=0
 f  s c=$$CHILD^MXMLDOM(h,1,c) q:'c  d
 . s drgcnt=drgcnt+1
 . n att s att=""
 . f  s att=$$ATTRIB^MXMLDOM(h,c,att) q:att=""  d
 .. s attval=$$VALUE^MXMLDOM(h,c,att)
 .. d DEBUG^XTMLOG("attrib "_att_"="_attval)
 .. i att="name"   s fda(176.2011,"+"_drgcnt_",+1,",.01)=$$TRIM^XLFSTR(attval)
 .. i att="rxnorm" s fda(176.2011,"+"_drgcnt_",+1,",.02)=$$TRIM^XLFSTR(attval)
 . ;
 . n c2 s c2=0
 . f  s c2=$$CHILD^MXMLDOM(h,c,c2) q:'c2  d
 .. s atccnt=atccnt+1
 .. d DEBUG^XTMLOG("child2 node value="_c2)
 .. f  s att=$$ATTRIB^MXMLDOM(h,c2,att) q:att=""  d
 ... s attval=$$VALUE^MXMLDOM(h,c2,att)
 ... d DEBUG^XTMLOG("attrib "_att_"="_attval)
 ... s fda(176.20111,"+"_atccnt_",+"_drgcnt_",+1,",.01)=$$TRIM^XLFSTR(attval)
 d
 . n $et,$es s $et="q:$es>1  s $ec="""",$zs="""""
 . D SAVEARR^XTMLOG($na(fda))
 d UPDATE^DIE("E",$na(fda),,$na(err))
 i $d(err) d ^%ZTER b
 d DELETE^MXMLDOM(h)
 quit
 ;
enDrug(path) ; [Public] - Import Entry Point for Drugs
 ; rm file data
 n z s z=^C0D(176.202,0)
 s $p(z,"^",3,4)=""
 k ^C0D(176.202)
 s ^C0D(176.202,0)=z
 ;
 N % S %=$$FILEINIT^XTMLOG("C0DIMP")
 n a s a("*.xml")=""
 n files
 n % s %=$$LIST^%ZISH(path,$na(a),$na(files))
 d DEBUG^XTMLOG("Directory is "_path)
 D SAVEARR^XTMLOG($na(files))
 n file s file=""
 f  s file=$o(files(file)) q:file=""  d drugFile(path,file)
 d ENDLOG^XTMLOG("C0DIMP")
 quit
 ;
drugFile(path,file) ; [Private] Import Each File - called ONLY by enDrug
 ; <?xml version="1.0" encoding="utf-8" ?>
 ; <INTERACTIONS>
 ; <INTERACTION>
 ; <SOURCE>
 ; <CLINICAL_SOURCE>ANSM</CLINICAL_SOURCE>
 ; <SOURCE_FILE>178-DIHYDROPYRIDINES.html
 ; </SOURCE_FILE>
 ; </SOURCE>
 ; <DRUG1>
 ; <CLASS nname="DIHYDROPYRIDINES" code="C08CA-002" /></DRUG1>
 ; <DRUG2>
 ; <CLASS name="BETA BLOCKING AGENTS (EXCEPT ESMOLOL)" code="C07AB-002" /></DRUG2>
 ; <DESCRIPTION>Hypotension, heart failure with patients having latent or uncontrolled cardiac insufficiency (addition of the negative inotropic effects). The beta blocking agent can furthermore minimize the sympathetic reflex reaction brought into play in the case of excessive hemodynamic repercussion</DESCRIPTION>
 ; <SEVERITY>Take into account</SEVERITY>
 ; </INTERACTION>
 ; <INTERACTION>
 ; <DRUG name="DIAZEPAM" rxcui="3322">
 ; <ATC code="N05BA01" />
 ; </DRUG>
 ; ...
 ;
 n fda,err              ; fda variables
 n desc,comm            ; mechaism and management
 n cnt s cnt=0          ; fda counter
 n cnt2 s cnt2=1000     ; ditto
 ;
 n h s h=$$EN^MXMLDOM(path_"/"_file,"W")
 d INFO^XTMLOG("XML Handle is "_h_" corresponding to "_file)
 ;
 n sourceFile
 n sourceFileNode s sourceFileNode=$$XPATH^MXMLPATH(,h,"//SOURCE_FILE")
 d TEXT^MXMLDOM(h,sourceFileNode,$na(sourceFile))
 s sourceFile=sourceFile(1)
 k sourceFile(1)
 d INFO^XTMLOG("Source file is "_sourceFile)
 ;
 K RTN D XPATH^MXMLPATH(.RTN,h,"/INTERACTIONS/INTERACTION/DRUG1")
 n n f n=0:0 s n=$o(RTN(n)) q:'n  d
 . s cnt=cnt+1
 . n iensl1 s iensl1="+"_cnt_","
 . n drug1Node s drug1Node=n
 . K ^TMP("C0DIMP",$J,file,drug1Node)
 . n drug1Child s drug1Child=$$CHILD^MXMLDOM(h,drug1Node)
 . n name s name=$$NAME^MXMLDOM(h,drug1Child)
 . n attr1 s attr1=$$ATTRIB^MXMLDOM(h,drug1Child)
 . n value1 s value1=$$VALUE^MXMLDOM(h,drug1Child,attr1)
 . n attr2 s attr2=$$ATTRIB^MXMLDOM(h,drug1Child,attr1)
 . i attr2="" d  k fda quit  ; Doesn't have an RxNorm
 .. S ^TMP("C0DIMP",$J,file,drug1Node,"norxn")=name_U_attr1_"="_value1
 . n value2 s value2=$$VALUE^MXMLDOM(h,drug1Child,attr2)
 . n drugClassName,classCode,rxncui
 . i attr1="name" s drugClassName=value1
 . i attr2="name" s drugClassName=value2
 . i attr1="code" s classCode=value1
 . i attr2="code" s classCode=value2
 . i attr1="rxcui" s rxncui=value1
 . i attr2="rxcui" s rxncui=value2
 . s fda(176.202,iensl1,.01)=$$TRIM^XLFSTR(drugClassName)
 . s fda(176.202,iensl1,.2)=$$TRIM^XLFSTR($g(rxncui))
 . s fda(176.202,iensl1,.3)=$$TRIM^XLFSTR($g(classCode))
 . s fda(176.202,iensl1,99)=$$TRIM^XLFSTR(sourceFile)
 . ;
 . s ^TMP("MXMLDOM",$j,h,"CURRENT-NODE")=drug1Child
 . N atcNodes D XPATH^MXMLPATH(.atcNodes,h,"ATC")
 . i $o(atcNodes(0)) d
 .. n atcNode s atcNode=0
 .. f  s atcNode=$o(atcNodes(atcNode)) q:'atcNode  d
 ... n attr1 s attr1=$$ATTRIB^MXMLDOM(h,atcNode)
 ... n atc s atc=$$VALUE^MXMLDOM(h,atcNode,attr1)
 ... s cnt2=cnt2+1
 ... n iensl2 s iensl2="+"_cnt2_","_iensl1
 ... s fda(176.2021,iensl2,.01)=$$TRIM^XLFSTR(atc)
 . ;
 . n drug2Node s drug2Node=$$SIBLING^MXMLDOM(h,drug1Node)
 . n drug2Child s drug2Child=$$CHILD^MXMLDOM(h,drug2Node)
 . n name s name=$$NAME^MXMLDOM(h,drug2Child)
 . n attr1 s attr1=$$ATTRIB^MXMLDOM(h,drug2Child)
 . n value1 s value1=$$VALUE^MXMLDOM(h,drug2Child,attr1)
 . n attr2 s attr2=$$ATTRIB^MXMLDOM(h,drug2Child,attr1)
 . i attr2="" d  k fda quit  ; Doesn't have an RxNorm
 .. S ^TMP("C0DIMP",$J,file,drug2Node,"norxn")=name_U_attr1_"="_value1
 . n value2 s value2=$$VALUE^MXMLDOM(h,drug2Child,attr2)
 . n drugClassName,classCode,rxncui
 . i attr1="name" s drugClassName=value1
 . i attr2="name" s drugClassName=value2
 . i attr1="code" s classCode=value1
 . i attr2="code" s classCode=value2
 . i attr1="rxcui" s rxncui=value1
 . i attr2="rxcui" s rxncui=value2
 . s fda(176.202,iensl1,2.1)=$$TRIM^XLFSTR(drugClassName)
 . s fda(176.202,iensl1,2.2)=$$TRIM^XLFSTR($g(rxncui))
 . s fda(176.202,iensl1,2.3)=$$TRIM^XLFSTR($g(classCode))
 . s ^TMP("MXMLDOM",$JOB,h,"CURRENT-NODE")=drug2Child
 . N atcNodes D XPATH^MXMLPATH(.atcNodes,h,"ATC")
 . i $o(atcNodes(0)) d
 .. n atcNode s atcNode=0
 .. f  s atcNode=$o(atcNodes(atcNode)) q:'atcNode  d
 ... n attr1 s attr1=$$ATTRIB^MXMLDOM(h,atcNode)
 ... n atc s atc=$$VALUE^MXMLDOM(h,atcNode,attr1)
 ... s cnt2=cnt2+1
 ... n iensl2 s iensl2="+"_cnt2_","_iensl1
 ... s fda(176.2023,iensl2,.01)=$$TRIM^XLFSTR(atc)
 . ;
 . n descriptionNode s descriptionNode=$$SIBLING^MXMLDOM(h,drug2Node)
 . d TEXT^MXMLDOM(h,descriptionNode,$na(desc(n)))
 . i $d(desc(n)) d reformatText(.desc,n) s fda(176.202,iensl1,5)=$na(desc(n))
 . d SAVEARR^XTMLOG($na(desc))
 . ;
 . n severityNode s severityNode=$$SIBLING^MXMLDOM(h,descriptionNode)
 . n sev d TEXT^MXMLDOM(h,severityNode,$na(sev))
 . i $g(sev(1))="" d  k fda quit
 .. S ^TMP("C0DIMP",$J,file,drug1Node,"nosev")=name_U_attr1_"="_value1
 . s sev=sev(1)
 . kill sev(1)
 . s sev=$$UP^XLFSTR(sev)
 . n sevShort s sevShort=$s(sev["CONTRA":"C",sev["NOT REC":"S",sev["PRECAU":"P",sev["TAKE INTO":"T",1:"")
 . s fda(176.202,iensl1,4)=sevShort
 . ;
 . n commentNode s commentNode=$$SIBLING^MXMLDOM(h,severityNode)
 . d TEXT^MXMLDOM(h,commentNode,$na(comm(n)))
 . i $d(comm(n)) d reformatText(.comm,n) s fda(176.202,iensl1,6)=$na(comm(n))
 . d SAVEARR^XTMLOG($na(comm))
 d SAVEARR^XTMLOG($na(fda))
 i $d(fda) d UPDATE^DIE(,$na(fda),,$na(err))
 i $d(err) d SAVEARR^XTMLOG($na(err)) b
 D DELETE^MXMLDOM(h)
 QUIT
 ;
reformatText(txt,n) ; [Private] Reformat word processing fields into 80 long lines
 k ^UTILITY($J,"W")
 n DIWL,DIWR,DIWF
 s DIWL=1,DIWR=80,DIWF=""
 n i,x f i=0:0 s i=$o(txt(n,i)) q:'i  s X=txt(n,i) d ^DIWP
 k txt(n)
 m txt(n)=^UTILITY($J,"W",1)
 quit
 ;
popVUID ; [Public] Populate VUIDs. Must be run AFTER drugs and groups are loaded
 s u="^"
 n fda
 n cnt1 s cnt1=10000000
 n cnt2 s cnt2=20000000
 N % S %=$$FILEINIT^XTMLOG("C0DIMP")
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d  ; for each entry
 . n e1 s e1=^C0D(176.202,i,0) ; entity 1
 . n e2 s e2=^C0D(176.202,i,2) ; entity 2
 . n n1,r1,c1,n2,r2,c2 ; name 1, rxnorm 1, class 1 etc
 . s n1=$p(e1,u,1)
 . s r1=$p(e1,u,2)
 . s c1=$p(e1,u,3)
 . s n2=$p(e2,u,1)
 . s r2=$p(e2,u,2)
 . s c2=$p(e2,u,3)
 . ;
 . d INFO^XTMLOG("Processing ien "_i_": "_n1_" vs "_n2)
 . i (r1="")&(c1="") d WARN^XTMLOG("No IDs for "_n1_" at IEN "_i_". Quitting.") quit
 . i (r2="")&(c2="") d WARN^XTMLOG("No IDs for "_n2_" at IEN "_i_". Quitting.") quit
 . ;
 . n vuids1,vuids2
 . i r1]"" d INFO^XTMLOG("Getting VUIDs for rxn "_r1) s vuids1=$$getVUIDsForRXN(r1)
 . i c1]"" d INFO^XTMLOG("Getting VUIDs for class "_c1) s vuids1=$$getVUIDsForClass(c1)
 . i vuids1="" d WARN^XTMLOG("No VUIDs found for "_n1_". Quitting.") quit
 . ;
 . i r2]"" d INFO^XTMLOG("Getting VUIDs for rxn "_r2) s vuids2=$$getVUIDsForRXN(r2)
 . i c2]"" d INFO^XTMLOG("Getting VUIDs for class "_c2) s vuids2=$$getVUIDsForClass(c2)
 . i vuids2="" d WARN^XTMLOG("No VUIDs found for "_n2_". Quitting.") quit
 . ;
 . n j,vuid,iens
 . f j=1:1:$l(vuids1,",") d
 .. s vuid=$p(vuids1,",",j)
 .. i vuid="" quit
 .. s cnt1=cnt1+1
 .. s iens="?+"_cnt1_","_i_","
 .. s fda(176.2027,iens,.01)=vuid
 . f j=1:1:$l(vuids2,",") d
 .. s vuid=$p(vuids2,",",j)
 .. i vuid="" quit
 .. s cnt2=cnt2+1
 .. s iens="?+"_cnt2_","_i_","
 .. s fda(176.2028,iens,.01)=vuid
 n err
 d DEBUG^XTMLOG("FDA Array","fda,",1)
 d:$d(fda) UPDATE^DIE(,$na(fda),,$na(err))
 i $d(err) b  ; ***
 ;
 d ENDLOG^XTMLOG("C0DIMP")
 quit
 ;
getVUIDsForRXN(rxn) ; [Private] Get VUIDs for this RxNorm Ingredient
 n otherRxns s otherRxns=$$getAllPossibleRXNs(rxn)
 d DEBUG^XTMLOG("Other rxns: "_otherRxns)
 n allrxns s allrxns=$s(otherRxns]"":rxn_","_otherRxns,1:rxn)
 n vuids s vuids=""
 n eachrxn
 n i,j
 ; ^C0CRXN(176.001,"STX","VANDF","IN",1366467,1008555)=4031768
 f i=1:1:$l(allrxns,",") s eachrxn=$p(allrxns,",",i) d
 . f j=0:0 s j=$o(^C0CRXN(176.001,"STX","VANDF","IN",eachrxn,j)) q:'j  s vuids=vuids_^(j)_","
 s $e(vuids,$l(vuids))="" ; rm trailing comma
 d DEBUG^XTMLOG("Returned VUIDs:"_vuids)
 quit vuids
 ;
getAllPossibleRXNs(inrxn) ; [Private] Get all RxNorms associated with a specific ingredient
 n rxns s rxns=""
 n ix
 for ix="part_of","form_of","has_form" do
 . n rxn for rxn=0:0 s rxn=$o(^C0CRXN(176.005,"B",inrxn,ix,rxn)) q:'rxn  s rxns=rxns_rxn_","
 s $e(rxns,$l(rxns))=""
 quit rxns
 ;
getVUIDsForClass(classID) ; [Private] Get all VUIDs associated with a class
 ; by iterating through all the rxnorm codes in the class
 n classIEN s classIEN=$o(^C0D(176.201,"C",classID,""))
 i 'classIEN d WARN^XTMLOG("NO CLASS OF "_classID) QUIT
 ;
 n vuids s vuids=""
 n i f i=0:0 s i=$o(^C0D(176.201,classIEN,1,i)) q:'i  d
 . n z s z=^C0D(176.201,classIEN,1,i,0)
 . n rxn s rxn=$p(z,u,2)
 . i 'rxn d WARN^XTMLOG("NO RXNORM FOR "_$p(z,u)) quit
 . n innervuids s innervuids=$$getVUIDsForRXN(rxn)
 . i innervuids]"" s vuids=vuids_innervuids_","
 s $e(vuids,$l(vuids))="" ; rm trailing comma
 d DEBUG^XTMLOG("Returned VUIDs:"_vuids)
 q vuids
 ;
crIndexFile ; [Public] Create the interactions file using VUID data.
 n z s z=^C0D(176.203,0)
 s $p(z,u,3,4)=""
 k ^C0D(176.203)
 s ^C0D(176.203,0)=z
 ;
 n newRec s newRec=0
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d
 . w i,!
 . n vuid1ien,vuid2ien,vuid1,vuid2
 . f vuid1ien=0:0 s vuid1ien=$o(^C0D(176.202,i,7,vuid1ien)) q:'vuid1ien  d
 .. w vuid1ien," "
 .. s vuid1=$p(^C0D(176.202,i,7,vuid1ien,0),u)
 .. f vuid2ien=0:0 s vuid2ien=$o(^C0D(176.202,i,8,vuid2ien)) q:'vuid2ien  d
 ... w vuid2ien," "
 ... s vuid2=$p(^C0D(176.202,i,8,vuid2ien,0),u)
 ... s newRec=newRec+1
 ... s ^C0D(176.203,newRec,0)=vuid1_u_vuid2_u_i
 ;
 N DIK,DA S DIK="^C0D(176.203," D IXALL^DIK
 quit
 ;
 ; QA Entry Points. Must use M-Unit.
 ;
 ; =============
TEST D EN^%ut($T(+0),3) QUIT
STARTUP ;
 K ^XTMP("C0DIMP")
 S ^XTMP("C0DIMP",0)=$$FMADD^XLFDT(DT,7)_U_DT_U_"Errors in data"
 QUIT
 ;
T1 ; @TEST Each entry in 176.202 must have either RxNorm or Class ID
 n u s u="^"
 n cnt s cnt=0
 S ^XTMP("C0DIMP","T1")=$T(T1)
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d
 . n e1 s e1=^C0D(176.202,i,0)
 . n e2 s e2=^C0D(176.202,i,2)
 . N e1nam s e1nam=$p(e1,u,1)
 . n e1rxn s e1rxn=$p(e1,u,2)
 . n e1cls s e1cls=$p(e1,u,3)
 . n e2nam s e2nam=$p(e2,u,1)
 . n e2rxn s e2rxn=$p(e2,u,2)
 . n e2cls s e2cls=$p(e2,u,3)
 . n sourceFile s sourceFile=^C0D(176.202,i,99)
 . i (e1rxn="")&(e1cls="") S ^XTMP("C0DIMP","T1",$i(cnt))=i_U_e1nam_U_e2nam_U_sourceFile
 . i (e2rxn="")&(e2cls="") S ^XTMP("C0DIMP","T1",$i(cnt))=i_U_e1nam_U_e2nam_U_sourceFile
 quit
 ;
T2 ; @TEST Each RxNorm in 176.202 must be a valid ingredient RxNorm
 n u s u="^"
 n cnt s cnt=0
 S ^XTMP("C0DIMP","T2")=$T(T2)
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d
 . n e1 s e1=^C0D(176.202,i,0)
 . n e2 s e2=^C0D(176.202,i,2)
 . N e1nam s e1nam=$p(e1,u,1)
 . n e1rxn s e1rxn=$p(e1,u,2)
 . n e2nam s e2nam=$p(e2,u,1)
 . n e2rxn s e2rxn=$p(e2,u,2)
 . n sourceFile s sourceFile=^C0D(176.202,i,99)
 . n c1a,c1b,c1c,c1d
 . n c2a,c2b,c2c,c2d
 . i e1rxn d
 .. s c1a=$data(^C0CRXN(176.001,"STC","RXNORM","IN",e1rxn))
 .. s c1b=$data(^C0CRXN(176.001,"STC","RXNORM","PIN",e1rxn))
 .. s c1c=$data(^C0CRXN(176.001,"STC","RXNORM","MIN",e1rxn))
 .. s c1d=$data(^C0CRXN(176.001,"STX","ATC","IN",e1rxn))
 . ;
 . i e2rxn d
 .. s c2a=$data(^C0CRXN(176.001,"STC","RXNORM","IN",e2rxn))
 .. s c2b=$data(^C0CRXN(176.001,"STC","RXNORM","PIN",e2rxn))
 .. s c2c=$data(^C0CRXN(176.001,"STC","RXNORM","MIN",e2rxn))
 .. s c2d=$data(^C0CRXN(176.001,"STX","ATC","IN",e2rxn))
 . ;
 . i e1rxn,'(c1a!c1b!c1c!c1d) D
 .. S ^XTMP("C0DIMP","T2",$i(cnt))=e1rxn_" not valid for "_e1nam_" in "_sourceFile
 .. S ^XTMP("C0DIMP","T2","UNIQ",e1rxn)=sourceFile
 . i e2rxn,'(c2a!c2b!c2c!c2d) D
 .. S ^XTMP("C0DIMP","T2",$i(cnt))=e2rxn_" not valid for "_e2nam_" in "_sourceFile
 .. S ^XTMP("C0DIMP","T2","UNIQ",e2rxn)=sourceFile
 ;
 ; Count uniques
 n cnt s cnt=0
 n name s name=""
 f  s name=$o(^XTMP("C0DIMP","T2","UNIQ",name)) q:name=""  set cnt=cnt+1
 s ^XTMP("C0DIMP","T2","UNIQ")=cnt
 quit
T3 ; @TEST Each Class in 176.202 must exist in 176.201.
 n u s u="^"
 n cnt s cnt=0
 S ^XTMP("C0DIMP","T3")=$T(T3)
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d
 . n e1 s e1=^C0D(176.202,i,0)
 . n e2 s e2=^C0D(176.202,i,2)
 . n sourceFile s sourceFile=^C0D(176.202,i,99)
 . N e1nam s e1nam=$p(e1,u,1)
 . n e1cls s e1cls=$p(e1,u,3)
 . n e2nam s e2nam=$p(e2,u,1)
 . n e2cls s e2cls=$p(e2,u,3)
 . i e1cls]"",'$data(^C0D(176.201,"C",e1cls)) d
 .. S ^XTMP("C0DIMP","T3",$i(cnt))="No class of category "_e1cls_" in "_sourceFile
 .. S ^XTMP("C0DIMP","T3","UNIQ",e1cls)=sourceFile
 . i e2cls]"",'$data(^C0D(176.201,"C",e2cls)) d
 .. S ^XTMP("C0DIMP","T3",$i(cnt))="No class of category "_e2cls_" in "_sourceFile
 .. S ^XTMP("C0DIMP","T3","UNIQ",e2cls)=sourceFile
 n cnt s cnt=0
 n name s name=""
 f  s name=$o(^XTMP("C0DIMP","T3","UNIQ",name)) q:name=""  set cnt=cnt+1
 s ^XTMP("C0DIMP","T3","UNIQ")=cnt
 quit
T4 ; @TEST Each RxNorm CUI in 176.202 must match the name of the IN in 176.001.
 n u s u="^"
 n cnt s cnt=0
 S ^XTMP("C0DIMP","T4")=$T(T4)
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d
 . n e1 s e1=^C0D(176.202,i,0)
 . n e2 s e2=^C0D(176.202,i,2)
 . n sourceFile s sourceFile=^C0D(176.202,i,99)
 . N e1nam s e1nam=$p(e1,u,1)
 . n e1rxn s e1rxn=$p(e1,u,2)
 . n e2nam s e2nam=$p(e2,u,1)
 . n e2rxn s e2rxn=$p(e2,u,2)
 . n x f x="e1rxn","e2rxn" i @x d
 .. n ien s ien=0
 .. i 'ien s ien=$o(^C0CRXN(176.001,"STC","RXNORM","IN",@x,ien))
 .. i 'ien s ien=$o(^C0CRXN(176.001,"STC","RXNORM","PIN",@x,ien))
 .. i 'ien s ien=$o(^C0CRXN(176.001,"STC","RXNORM","MIN",@x,ien))
 .. i 'ien s ien=$o(^C0CRXN(176.001,"STX","ATC","IN",@x,ien))
 .. i 'ien quit
 .. n name s name=$p(^C0CRXN(176.001,ien,0),u,15)
 .. i x="e1rxn",$$UP^XLFSTR(e1nam)'=$$UP^XLFSTR(name) d
 ... S ^XTMP("C0DIMP","T4",$i(cnt))=e1nam_"|"_name
 ... S ^XTMP("C0DIMP","T4","UNIQ",e1nam_"|"_name)=sourceFile
 .. i x="e2rxn",$$UP^XLFSTR(e2nam)'=$$UP^XLFSTR(name) d
 ... S ^XTMP("C0DIMP","T4",$i(cnt))=e2nam_"|"_name
 ... S ^XTMP("C0DIMP","T4","UNIQ",e2nam_"|"_name)=sourceFile
 ;
 ; Count uniques
 n cnt s cnt=0
 n name s name=""
 f  s name=$o(^XTMP("C0DIMP","T4","UNIQ",name)) q:name=""  set cnt=cnt+1
 s ^XTMP("C0DIMP","T4","UNIQ")=cnt
 quit
T5 ; @TEST Each Class in 176.202 must match the name of the class in 176.201.
 n u s u="^"
 n cnt s cnt=0
 S ^XTMP("C0DIMP","T5")=$T(T5)
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d
 . n e1 s e1=^C0D(176.202,i,0)
 . n e2 s e2=^C0D(176.202,i,2)
 . n e1nam s e1nam=$p(e1,u,1)
 . n e1cls s e1cls=$p(e1,u,3)
 . n e2nam s e2nam=$p(e2,u,1)
 . n e2cls s e2cls=$p(e2,u,3)
 . i e1cls]"",$data(^C0D(176.201,"C",e1cls)) d
 .. n ien s ien=$o(^C0D(176.201,"C",e1cls,0))
 .. n name s name=$p(^C0D(176.201,ien,0),u)
 .. i e1nam'=name d
 ... S ^XTMP("C0DIMP","T5",$i(cnt))=e1nam_"|"_name
 ... S ^XTMP("C0DIMP","T5","UNIQ",e1nam_"|"_name)=""
 . i e2cls]"",$data(^C0D(176.201,"C",e2cls)) d
 .. n ien s ien=$o(^C0D(176.201,"C",e2cls,0))
 .. n name s name=$p(^C0D(176.201,ien,0),u)
 .. i e2nam'=name d
 ... S ^XTMP("C0DIMP","T5",$i(cnt))=e2nam_"|"_name
 ... S ^XTMP("C0DIMP","T5","UNIQ",e2nam_"|"_name)=""
 ;
 ; Count uniques
 n cnt s cnt=0
 n name s name=""
 f  s name=$o(^XTMP("C0DIMP","T5","UNIQ",name)) q:name=""  set cnt=cnt+1
 s ^XTMP("C0DIMP","T5","UNIQ")=cnt
 quit
 ;
T6 ; @TEST Each Interaction must have a severity
 n u s u="^"
 n cnt s cnt=0
 S ^XTMP("C0DIMP","T4")=$T(T4)
 n i f i=0:0 s i=$o(^C0D(176.202,i)) q:'i  d
 . n e1 s e1=^C0D(176.202,i,0)
 . n e2 s e2=^C0D(176.202,i,2)
 . n e1nam s e1nam=$p(e1,u,1)
 . n e2nam s e2nam=$p(e2,u,1)
 . n sourceFile s sourceFile=^C0D(176.202,i,99)
 . n sev s sev=^C0D(176.202,i,4)
 . i sev="" S ^XTMP("C0DIMP","T6",$i(cnt))=e1nam_" vs "_e2nam_" in "_sourceFile_" has no severity"
 quit
 ;
assert(x,y) d CHKTF^%ut(x,$g(y)) quit
 ;
