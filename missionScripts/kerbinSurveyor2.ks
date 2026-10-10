//This is the unique script for the kerbin surveyor 2 vehicle and its mission

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

//initialize mission memory file
global mmValues is lexicon().
if not(core:VOLUME:FILES:HASKEY("missionMemory.json")) {
    set mmValues to lexicon("mission phase", "").
    writeJson(mmValues, "missionMemory.json").
}
else {
    loadMM().
}

function main{
    until false {
        if ship:STATUS = "PRELAUNCH" {
            updateMissionMem("mission phase", "prelaunch").
            launchToOrbit().
            loadMM().
        }
        else  if mmValues["mission phase"] = "LKO" {
            print "In orbital mission loop:".
            performOrbitalMission().
        }
        else {
            print "Mission appears to be complete. Program terminating.".
            break.
        }
    }
}

function launchToOrbit {
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   100000,  //Target apoapsis
                356,     //Target heading
                130,    //max pitch drop
                80000,  //scale altitude
                0.9,    //curvature
                50).    //time to apoapsis throttleback
    doShutdown().//from vertLaunchUtils.lib.ks
    print "ascent complete, coasting to 70km altitude" at (0,10).
    lock steering to prograde.
    wait until ship:STATUS = "SUB_ORBITAL".
    //circularize orbit
    print "circularizing orbit...".
    doCircularization().//from orbitalMnvUtils.lib.ks
    updateMissionMem("mission phase", "LKO").
}

function performOrbitalMission {
    if not(mmValues:HASKEY("antenna status")) {
        deployAntenna().
        updateMissionMem("antenna status", "deployed").
        loadMM().
    }
    if not(mmValues:HASKEY("solar status")) {
        deploySolarPanels().
        updateMissionMem("solar status", "deployed").
        loadMM().
    }
    if not(mmValues:HASKEY("scanner status")) {
        deployScanner().
        updateMissionMem("scanner status", "deployed").
        loadMM().
    }
    print "Orienting spacecraft to face the planet".
    lock steering to heading(90, 90).
    until false {wait 1.}
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

function loadMM {
    set mmValues to readJson("missionMemory.json").
}

main().