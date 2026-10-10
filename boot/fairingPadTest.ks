//This script will automatically find and deploy the main fairing at the launch
//pad, if the fairing is tagged "main fairing".

//include the needed library scripts for the visual studio code extension
// #include "0:/utilsLibrary/vesPtMgmntUtils.lib.ks"

//load the library scripts onto the vessel and run them
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "utilsLibrary/".
    local neededLibaries is list(
        "vesPtMgmntUtils.lib.ks"
    ).
    cd("1:/library").
    for lib in neededLibaries {
        print "copying " + lib.
        copyPath("0:/" + libSourceDir + lib,"").
    }
    print "Initializing libraries contents...".
    list files in libraryList.
    for file in libraryList {
        if file:ISFILE {
            print "running " + file:NAME.
            runOncePath(file).
        }
    }
}
switch to 1.

attemptEventOnTagged("main fairing", "deploy").