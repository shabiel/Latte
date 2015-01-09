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

![MOCHA flow](./mocha.png)

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

![Latte flow](./latte.png)

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

## Installation for Latte
Check each folder for installation instructions.

* Latte 1.0 should not be installed. It's kept here for historical reasons.
* Latte 2.0 should be installed for all MOCHA 1.0 and MOCHA 1.0 Enhancements
  systems.
* Latte 3.0 should be installed for all MOCHA 2.0 systems. As of the time
  of the writing of this document, MOCHA 2.0 Enhancements and 2.1 have not
  been released yet. When they are released, Latte will be updated to include
  the latest changes in the routines.

### RxNorm Installation Warning

*BECAUSE RXNORM DATA IN ^C0CRXN ARE REFERENCE DATA THAT CONTAIN 2.5 GB OF TOTAL
DATA, IT IS HIGHLY RECOMMENDED THAT YOU MAP ^C0CRXN TO AN UNJOURNALED REGION OF
YOUR MUMPS DATABASE. IT'S ALSO RECOMMENDED THAT YOU PUT IT IN A SEPARATE DATA
FILE OTHER THAN YOUR MAIN VISTA DATABASE. BOTH CACHE AND GT.M HAVE WAYS YOU CAN
ACCOMPLISH THAT.*

