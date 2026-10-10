wait until ship:unpacked.
clearscreen.

//include the needed library scripts for the visual studio code extension
// #include "0:/utilsLibrary/vertLaunchUtils.lib.ks"
// #include "0:/utilsLibrary/orbitalMnvUtils.lib.ks"
// #include "0:/utilsLibrary/vesPtMgmntUtils.lib.ks"
// #include "0:/utilsLibrary/missionManUtils.lib.ks"

//load the library scripts onto the vessel and run them
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if homeConnection:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "utilsLibrary/".
    local neededLibaries is list(
        "vertLaunchUtils.lib.ks",
        "orbitalMnvUtils.lib.ks",
        "vesPtMgmntUtils.lib.ks",
        "missionManUtils.lib.ks"
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
    // deployAntenna().
    // deploySolarPanels().
    // deployScanner().
    stage.
}

function deployAntenna {
    print "deploying antenna".
    attemptEventOnTagged("main transmitter", "extend antenna").
}

function deploySolarPanels {
    print "deploying solar panels".
    findAndDoAnyEvent("extend solar panel").
}

function deployScanner {
    print "deploying the scanner".
    attemptEventOnTagged("main scanner", "Start Scan: RADAR").
}

main().