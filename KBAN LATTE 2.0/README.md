# Latte (MOCHA Bypass)
Latte is a KIDS build to apply to VISTA. It will allow you to run VISTA
pharmacy and CPRS without the need for an external data source for drugs. It
ships with an interface to Drug Information Technologies (DIT). Latte restores
VISTA's ability to use its own drug files to do the drug-related order checks
by leveraging the MOCHA interface and decoupling the interface from the First
Databank Generic Code Number (GCN). Latte also allows you to interface to
alternate databases other than First Databank.

* This will become a table of contents
{:toc}

## License

(C) Sam Habiel 2015.

Latte comes under an open source license (AGPL 3.0). A commercial license is
available for commercial VISTA users for whom an open source license is
inappropriate. The open source license text is available in the files you
received as LICENSE.txt. The commercial license is available as
LICENSE-COMMERCIAL.txt. If you are unsure which license applies to you, contact
the author at <sam.habiel@vistaexpertise.net>.

## Statement of Problem to Solve
Starting in February 2011, Drug Order Checking in VISTA (drug interactions and
duplicate drug classes) was replaced with web service calls to an external
program that looks at First Databank data combined with VA customized data.
This external program runs on Oracle or Cache as databases and WebLogic as the
server. Without a license with First Databank, and the associated Oracle and
WebLogic licenses for the middleware, you can no longer use VISTA for order
checking. Furthermore, the ability to update CPRS and Pharmacy in your VISTA
instance beyond February 2011 is impaired.

Three order checks are supported by MOCHA:

 * Drug-Drug Interaction Checks
 * Duplicate Therapy Checks
 * Dosage Checks

The general flow of data in MOCHA looks like this:

![MOCHA flow](../mocha.png)

## Solution
Latte intercepts the XML from VISTA in the routine PSSHTTP and sends it to
KBANLATT. KBANLATT reads the XML and performs the requested operations (Drug
Interactions or Duplicate Therapy Checks) against the DRUG INTERACTION file or
the VA DRUG CLASS file, as appropriate. It does not do dosage checks because
VISTA does not support that. The KIDS build also includes changes to pharmacy
routines to prevent their reliance on GCNs.

If you use the DIT interface, KBANLATT calls KBANLDIT which makes the web
service calls to DIT. Drugs are checked with DIT using the RxNorm code, which
is derived from VISTA.

The drugs are extracted from the XML message and matched to VISTA using their
VUIDs, which are sent in the message.

The new flow looks like this:

![Latte flow](../latte.png)

## Limitations
Because the DRUG INTERACTION file does not have any text content on the
interaction, only the severity of the interaction is returned. Other content
expected from the MOCHA interface is replaced with pre-programmed values.

If you use the DIT interface, all the data is supplied back.

Dosage checks are currently disabled in VISTA. If they are enabled and
requested they always return an empty tag to prevent VISTA from going into
MOCHA error processing mode.

## Toggling between MOCHA and Latte
The parameter `PSS KBAN LATTE ENABLE?` is supplied to enable you to switch
between MOCHA and Latte. A value of `Yes` enables Latte. When you install
Latte, it's turned on by default.

## User interaction changes.
No changes are performed to the user interface.

## Installation for Latte 2.0
Before you start installation, you must make sure that you have at least
MOCHA 1.0 installed.

*IF YOU HAVE MOCHA 2.0 INSTALLED, YOU NEED TO USE Latte 3.0.* The pre-install
on the builds ensures that you have the right patch level.

### RxNorm Installation Warning

*BECAUSE RXNORM DATA IN ^C0CRXN ARE REFERENCE DATA THAT CONTAIN 2.5 GB OF TOTAL
DATA, IT IS HIGHLY RECOMMENDED THAT YOU MAP ^C0CRXN TO AN UNJOURNALED REGION OF
YOUR MUMPS DATABASE. IT'S ALSO RECOMMENDED THAT YOU PUT IT IN A SEPARATE DATA
FILE OTHER THAN YOUR MAIN VISTA DATABASE. BOTH CACHE AND GT.M HAVE WAYS YOU CAN
ACCOMPLISH THAT.*

### Install Order
All KIDS installations are normal installations. It's preferred that Pharmacy
users are off the system during this installation.

In order to make installation easy, the author recommends downloading all the
builds/files before starting installations. The order must be followed to 
satisfy all the dependencies.

Latte without DIT:
 * XML_PROCESSING_UTILITIES_2P2.KID <https://raw.githubusercontent.com/shabiel/VISTA-xml-processing-utilities/master/kids/XML_PROCESSING_UTILITIES_2P2.KID>
 * KBAN_LATTE_2P0.KID

Additional packages for DIT:
 * RXNORM_FOR_VISTA_2P3.KID <https://trac.opensourcevista.net/svn/ccr/trunk/rxnorm/tags/2.3/RXNORM_FOR_VISTA_2P3.KID>
 * RXNORM_FOR_VISTA_PD_DATA_11P2013.GKID (or a more recent version) *(see warning above)* <https://trac.opensourcevista.net/svn/ccr/trunk/rxnorm/tags/2.2/RXNORM_FOR_VISTA_PD_DATA_11P2013.GKID.7z>
 * Download this routine and file in routine directory: <https://raw.github.com/shabiel/M-Web-Server/master/src/_WC.m>

All of these installations will take less than 5 seconds to complete except for
the RxNorm global build, which will take about 30-60 minutes.

### Install success check

Following installation, you can run the menu option `PSS CHECK PEPS SERVICES
SETUP` to check Latte functionality. The output will be as follows. The dosing
check error is expected as Latte does not do dosing checks.

	GTM>D ^XUP

	Setting up programmer environment
	This is a TEST account.

	Terminal Type set to: C-VT220

	Select OPTION NAME: PEPS SERVICES  PSS PEPS SERVICES     PEPS Services


			  Check Vendor Database Link
			  Check PEPS Services Setup
			  Schedule/Reschedule Check PEPS Interface
			  Print Interface Data File

	Select PEPS Services Option: CHECK PEPS Services Setup

	This option performs several checks. You may queue this report if you wish.

	Among these checks are:
	-----------------------
	A connection check to the Vendor Database
	Drug-Drug Interaction Check
	Duplicate Therapy Order Check
	Dosing Order Check
	Custom Drug-Drug Interaction Check

	Select Device: HOME//   TELNET

	Checking Vendor Database Connection...OK

	Enter RETURN to continue or '^' to exit: 
	Performing Drug-Drug Interaction Order Check for ASPIRIN 325MG TAB and WARFARIN
	10MG TAB...OK 

	   Significant Drug Interaction: Clinical Effects not available in this
	   interface 

	Enter RETURN to continue or '^' to exit: 
	Performing Duplicate Therapy Order Check for CIMETIDINE 300MG TAB and
	RANITIDINE 150MG TAB...OK 

	   Therapeutic Duplication with CIMETIDINE 300MG TAB and RANITIDINE 150MG TAB 
	   Duplicate Therapy Class(es): ANTIULCER AGENTS, 

	Enter RETURN to continue or '^' to exit: 
	Performing Dosing Order Check for ACETAMINOPHEN 500MG TAB - 3000MG Q4H...Not OK 

	   Dosing Order Check could not be performed.  

	Enter RETURN to continue or '^' to exit: 
	Performing Custom Drug-Drug Interaction Order Check for CLARITHROMYCIN 250MG
	TAB and DIAZEPAM 5MG TAB...OK 

	   Significant Drug Interaction: Clinical Effects not available in this
	   interface 


	Enter RETURN to continue or '^' to exit: 

If all you have to install is Latte without the DIT interface, then you are
done.

### DIT Configuration

To install DIT, you need to get a license first from Drug Information
Technologies Inc. at <http://www.ditonline.com>. Once acquired, ask for a
UCI key to use with the web services. Ask for the server and port to use as
well.

Once you have that information, you are ready to set-up the web services.
All web services can be set-up in VISTA using the menu option `XOBW WEB SERVER
MANAGER`.

Using a user whose Fileman access code is '@', Invoke option `XOBW WEB SERVER
MANAGER`. You will see the following screen. Type `WS` at the prompt.

<pre>
    Web Server Manager            Jun 20, 2013@15:39:52          Page:    1 of    1 
                           HWSC Web Server Manager
                          Version: 1.0     Build: 31
    
     ID    Web Server Name           IP Address or Domain Name:Port                 
    
    
    
    
    
              Legend:  *Enabled                                                     
    AS  Add Server                          TS  (Test Server)
    ES  Edit Server                         WS  Web Service Manager
    DS  Delete Server                       CK  Check Web Service Availability
    EP  Expand Entry                        LK  Lookup Key Manager
    Select Action:Quit// WS
</pre>

Select AS and enter the Web Services needed.

<pre>
    Web Service Manager           Jun 20, 2013@16:25:25          Page:    1 of    1 
                           HWSC Web Service Manager
                          Version: 1.0     Build: 31

     ID    Web Service Name           Type   URL Context Root                       
    
    
    
    
              Enter ?? for more actions                                             
    AS  Add Service
    ES  Edit Service
    DS  Delete Service
    EP  Expand Entry
    Select Action:Quit// AS
</pre>

Enter the data for DIT INFO as shown here, replacing your UCI with the UCI
you acquired from DIT. (Make sure to replace the entire '{UCI}' designation
below).

<pre>
    Select WEB SERVICE NAME: DIT INFO
    Are you adding 'DIT INFO' as a new WEB SERVICE (the 1ST)? No// Y
    NAME: DIT INFO//
    DATE REGISTERED: N (Jan 23, 2011@12:49:27)
    TYPE: REST REST
    CONTEXT ROOT: /DIT/distinctdrugsbyrxcui/{UCI}/
    AVAILABILITY RESOURCE:
</pre>

Once the data for DIT INFO is done, enter the data for DIT IXN MONOGRAPH as 
shown here, replacing the UCI appropriately.

<pre>
    Select WEB SERVICE NAME: DIT IXN MONOGRAPH
    Are you adding 'DIT IXN MONOGRAPH' as a new WEB SERVICE (the 2nd)? No// Y
    NAME: DIT IXN MONOGRAPH//
    DATE REGISTERED: N (Jan 23, 2011@12:49:27)
    TYPE: REST REST
    CONTEXT ROOT: /DIT/interactionfulltext/{UCI}/
    AVAILABILITY RESOURCE:
</pre>


Once the data for DIT IXN MONOGRAPH is done, enter the data for DIT IXNS as 
shown here, replacing the UCI appropriately.

<pre>
    Select WEB SERVICE NAME: DIT IXNS
    Are you adding 'DIT IXNS' as a new WEB SERVICE (the 3rd)? No// Y
    NAME: DIT IXNS//
    DATE REGISTERED: N (Jan 23, 2011@12:49:27)
    TYPE: REST REST
    CONTEXT ROOT: /DIT/interactionsbyrxcui/{UCI}/
    AVAILABILITY RESOURCE:
</pre>

When completed, the three Web Services will appear as shown below:
    
<pre>
    Web Service Manager           Jun 20, 2013@16:35:25          Page:    1 of    1 
                           HWSC Web Service Manager
                          Version: 1.0     Build: 31
    
     ID    Web Service Name           Type   URL Context Root                       
     1     DIT INFO                   REST   /DIT/distinctdrugsbyrxcui/{UCI}/
     2     DIT IXN MONOGRAPH          REST   /DIT/interactionfulltext/{UCI}/ 
     3     DIT IXNS                   REST   /DIT/interactionsbyrxcui/{UCI}/ 

    
    
    
              Enter ?? for more actions                                             
    AS  Add Service
    ES  Edit Service
    DS  Delete Service
    EP  Expand Entry
    Select Action:Quit// 
    
</pre>
DIT INFO, DIT IXN MONOGRAPH, and DIT IXNS must be entered exactly as shown above.

After building the Web Services you must enter or edit the Web Server and
assign the Web Services to the server. In this case, the DIT server must be
entered from the Web Server manager and Web services should be assigned as
shown in the screens that follow. The server and the port will be assigned to
you by DIT.

<pre>
    Web Server Manager            Jun 20, 2013@15:39:52          Page:    1 of    1 
                           HWSC Web Server Manager
                          Version: 1.0     Build: 31
    
     ID    Web Server Name           IP Address or Domain Name:Port                 
    
    
    
    
    
              Legend:  *Enabled                                                     
    AS  Add Server                          TS  (Test Server)
    ES  Edit Server                         WS  Web Service Manager
    DS  Delete Server                       CK  Check Web Service Availability
    EP  Expand Entry                        LK  Lookup Key Manager
    Select Action:Quit// **AS**
    Select WEB SERVER NAME: DIT DI SERVICE
    Are you adding 'DIT DI SERVICE' as a new WEB SERVER (the 1ST)? No// y
    NAME: DIT DI SERVICE//
    SERVER: rest.eprax.de
    PORT: 80//
    DEFAULT HTTP TIMEOUT: 30// 5
    STATUS: E ENABLED
    (Yes)
    Security Credentials
    ====================
    LOGIN REQUIRED:
    Authorize Web Services
    ======================
    Select WEB SERVICE: DIT INFO
    Are you adding 'DIT INFO' as
    a new AUTHORIZED WEB SERVICES (the 1ST for this WEB SERVER)? No// Y (Yes)
    STATUS: E ENABLED
    Select WEB SERVICE: DIT IXN MONOGRAPH
    Are you adding 'DIT IXN MONOGRAPH' as
    a new AUTHORIZED WEB SERVICES (the 2ND for this WEB SERVER)? No// Y (Yes)
    STATUS: E ENABLED
    Select WEB SERVICE: DIT IXNS
	Are you adding 'DIT IXNS' as
	a new AUTHORIZED WEB SERVICES (the 3RD for this WEB SERVER)? No// Y (Yes)
    STATUS: E ENABLED
    Select WEB SERVICE:
</pre>

The Server and Port numbers in the example can change if DIT tells you to
connect to a different server.

The name of the server, DIT DI SERVICE, and its respective services, DIT IXN 
MONOGRAPH, DIT INFO and DIT IXNS, must remain static. These names are used in the
interface code to access the correct Web server and services.  As stated
previously, the only data elements that should change are the IP address or the
port number and the UCI.

### Install Check for DIT

Once you are done, you can run the tests for the web service using `PSS CHECK PEPS SERVICES SETUP` as before.

<pre>
Select PEPS Services Option: CHECK PEPS Services Setup

This option performs several checks. You may queue this report if you wish.

Among these checks are:
-----------------------
A connection check to the Vendor Database
Drug-Drug Interaction Check
Duplicate Therapy Order Check
Dosing Order Check
Custom Drug-Drug Interaction Check

Select Device: HOME//   TELNET

   Checking Vendor Database Connection...OK

   Enter RETURN to continue or '^' to exit: 
   Performing Drug-Drug Interaction Order Check for ASPIRIN 325MG TAB and WARFARIN
   10MG TAB...OK 

   Significant Drug Interaction: increased risk of bleeding due to blood
   thinning and antiplatelet activity / Relevance: Dangerous / Frequency:
   Frequent 

   Enter RETURN to continue or '^' to exit: 
   Performing Duplicate Therapy Order Check for CIMETIDINE 300MG TAB and
   RANITIDINE 150MG TAB...OK 

   Therapeutic Duplication with CIMETIDINE 300MG TAB and RANITIDINE 150MG TAB 
   Duplicate Therapy Class(es): Histamine H2 Receptor Antagonists
   [MoA],Histamine-2 Receptor Antagonist [EPC], 

   Enter RETURN to continue or '^' to exit: 
   Performing Dosing Order Check for ACETAMINOPHEN 500MG TAB - 3000MG Q4H...Not OK 

   Dosing Order Check could not be performed.  

   Enter RETURN to continue or '^' to exit: 
   Performing Custom Drug-Drug Interaction Order Check for CLARITHROMYCIN 250MG
   TAB and DIAZEPAM 5MG TAB...OK 

   Significant Drug Interaction: benzodiazepine metabolism decreased /
   Relevance: Important / Frequency: Possible 
</pre>

This concludes the installation section.

## Troubleshooting
Because VUIDs are used to match drugs back against VISTA, each drug that
will participate in a drug interaction should be matched against the 
National Drug File.

If you encounter the message that a drug cannot be checked and you have to
manually check it when using Latte, this means that the VUID sent in the
XML message could not be matched back to the National Drug File. In my testing
this happens mostly due to corruption in the AMASTERVUID index of the VA
PRODUCT file. To fix this, re-index it. In one instance (DEXTROSE 5% INJ),
there were two MASTER entries for the drug, making the resolution impossible 
until one of these entries is marked as non-Master.

With the DIT interface, there is the possibility that you requested a drug that
could not be found in RxNorm. This is unlikely but could happen on a supply
item. By default, supply items are excluded from interaction checking. However,
if the supply item is incorrectly marked to be checked for interaction
checking, then this error is possible.

## Technical Components
### Dependencies
 * Kernel 8
 * Fileman 22
 * Pharmacy Patches below (MOCHA enhancements optional)
 > * MOCHA 1.0: PSS\*1\*117, PSO\*7\*251, PSJ\*5\*181, OR\*3\*272, PSO\*7\*375, PSS\*1\*163
 > * MOCHA 1.0 Enhancements 1: PSO\*7\*390, PSO\*7\*417, PSJ\*5\*260, PSJ\*5\*268,PSJ\*5\*288, PSS\*1\*164, PSS\*1\*169, OR\*3\*352
 * XML Processing Utilities 2.0 <https://github.com/shabiel/VISTA-xml-processing-utilities>

### Additional Dependencies for the DIT interface
 * %WC routine for web service calls: <https://raw.github.com/shabiel/M-Web-Server/master/src/_WC.m>
 * RxNorm For VISTA (v2.2 at least) data dictionaries and data file (data file updated monthly):
   <https://trac.opensourcevista.net/svn/ccr/trunk/rxnorm/tags/2.2/>

### Routine list

Patch 11310000 indicates a modification to a National Routine to support Latte.

					 Checksums
	Routine         Old         New        Patch List
	KBANLATT        n/a      75813646    
	KBANLDIT        n/a      235470197   
	KBANLUT1        n/a      159065169   
	KBANLWRT        n/a      196654115   
	PSODDPRE        n/a      135966725   **251,375,387,379,390,11310000**
	PSSHRIT         n/a      219536105   **136,168,164,11310000**
	PSSHRQ22        n/a      61732001    **136,11310000**
	PSSHRVAL        n/a      153337864   **136,11310000**
	PSSHTTP         n/a      17204961    **136,11310000**


### Description of routines and overall flow
PSSHTTP is the central point where MOCHA messages are sent out to be checked.
PSSHTTP invokes KBANLATT, if the parameter `PSS KBAN LATTE ENABLE?` is 
enabled. Otherwise, it invokes the HWSC routines (XOBW\*).

KBANLATT is responsible for deserializing the XML received from PSSHTTP.  Then
it performs the interaction and therapy duplication checking.  In case of the
existence of the DIT interface, the checks are diverted to KBANLDIT. In either
case, when the checks are done, the output is sent to the routine KBANLWRT to
write out the final XML resulting from the checks.  After this, the control is
returned back to PSSHTTP and it parses the output.

KBANLUT1 is a Unit Testing routine. It uses M-Unit which you have to install
separately.

#### Modifications to National VA distributed routines
 * PSODDPRE has been modified to enable proceeding for interacting drugs even
   when no GCN can be found for the drug.
 * PSSHRIT has been modified to correct a wrong VUID that came in the FOIA
   and to check for different severities for interactions because DIT returns
   a different severity for a tested interaction.
 * PSSHRQ22 deduplicates duplicate therapy drugs using an array subscripted by
   GCN. Since GCNs are not used in Latte, subscript the array using VUIDs,
   which are always guaranteed to be defined.
 * PSSHRVAL validates XML messages before they get sent out. In FOIA, it checks
   that the drugs contain GCNs. Again, since GCNs are not used in Latte,
   we don't perform that check.
 * PSSHTTP was modified to intercept XML messages if the parameter
   `PSS KBAN LATTE ENABLE?` is defined and send them to Latte. It has also
   been modified to bullet proof the error trap.

### File list
None included.

### Exported Options
None included.

### Archiving and Purging
Not supported.

### Supported APIs

	EN^KBANLATT(RESULT,DOCHAND) ; Public; Main Latte XML parser routine                      
	 ; RESULT - Result to send back; By Ref 
	 ; DOCHAND - MXML Document Hand; By Val                                         

### External Interfaces, External Relations
None

### Internal relations
Only call is from PSSHTTP.

### Package wide-variables
None.

### Security
This software implements no security of its own. It inherits pharmacy security.
