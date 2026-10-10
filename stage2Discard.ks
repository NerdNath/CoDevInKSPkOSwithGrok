//This script is for loading onto a second stage computer and running to discard

// clearscreen.
//include the needed library scripts for the visual studio code extension
// #include "0:/utilsLibrary/orbitalMnvUtils.lib.ks"

//load the library scripts onto the vessel and run them
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "utilsLibrary/".
    local neededLibaries is list(
        "orbitalMnvUtils.lib.ks"
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

runOncePath("0:/utilsLibrary/orbitalMnvUtils.lib.ks").
doCollisionDeorbit().