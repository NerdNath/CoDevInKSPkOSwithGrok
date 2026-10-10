//This script will search for parts to run a test on, and run the test(s). It 
//assumes that the contract is for a test while landed, or at the launch pad,
//because it will not fly the vessel anywhere into any other more complicated
//test conditions

//include the needed library scripts for the visual studio code extension
// #include "0:/utilsLibrary/careerMgmntUtils.lib.ks"

//load the library scripts onto the vessel and run them
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "utilsLibrary/".
    local neededLibaries is list(
        "careerMgmntUtils.lib.ks"
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

function main {
    searchAndCompletePartTest().
}

main().