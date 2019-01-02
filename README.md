# Convert a Paribas BNP CSV to a YNAB CSV

A ruby script and folder action that embeds a copy of the script to convert CSV exports from Paribas BNP to YNAB.

## Installation

Automator is janky. The basic procedure here is to install a copy of the `ConvertBNPToYNAB` workflow and then attach it as a folder action to a folder.

1. Double-click the unzipped workflow and choose to "Open with Automator"
2. In Automator, at the top of the right side, select a folder where you'll drop CSVs from your bank to have them converted to the YNAB format. Because Automator is a bit janky, the folder doesn't really matter that much, but this is a good time to create the folder where you'll want it.
3. In Automator, Save, then Quit.
4. In Finder, double-click the workflow file again, and this time choose "Install". This will install the workflow to `Library/Workflows/Applications/Folder Actions`, but because Automator is a bit janky, it won't actually enable the folder action, even though it says it does.
5. In Finder, right-click on the folder you set up (where you'll drag CSVs from your bank) and select "Folder Actions Setup…"
6. In the Folder Actions Setup application that opens, select `ConvertBNPToYNAB` to attach the action we installed to this folder. Now you can Quit Folder Actions Setup.

## Use

If installation worked as expected, you should be able to drag a CSV from your bank into the folder that you set up. You should see a little gear icon show up in your menu bar at the top of the screen while the attached action runs. The action will create a subfolder called "YNAB" and put a converted CSV, ready for import into YNAB, into that folder. It will then delete the CSV you dragged in (option-drag into the folder to make a copy of the original if you don't want to delete it).

You can import the YNAB-formatted CSV into YNAB by dragging the file onto your YNAB transactions (in a browser) and clicking through the dialog that pops up.