ATL09 Quick View README

This is a MATLAB function that will read select parameters from the ATL09 files, save the output as a .mat file, plot the calibrated attenuated backscatter, and save the output as a .png file.

Function is run via the run_ATL09QuickView.m file.


*** BEFORE RUNNING ***

In the "Define input and output directories" section, change the paths as necessary for your particular machine.

If any file is not able to be processed, the error message will be saved to a text file and the function will go on to the next ATL09 file in your data directory.


Within the "Set processing flags" section:

The function is not particularly fast. If you don't need to save the ATL09 output, you can save processing time by setting saveOutput to false.

Additionally, if you don't want the figures popping up while it's running (only saved to file), change the figVis to 'off'.
