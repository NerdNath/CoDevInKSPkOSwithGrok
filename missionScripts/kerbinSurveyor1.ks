//This is the unique script for the curious 1 vehicle and its mission

//include the needed library scripts
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "virdestLibrary/".
    local neededLibaries is list(
        "vertLaunchUtils.lib.ks",
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

function main{
    until false {
        if ship:STATUS = "PRELAUNCH" {
            launchToOrbit().
        }
        else  {
            print "In orbital mission loop:".
            performOrbitalMission().
        }
    }
}

function launchToOrbit {
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   80000,  //Target apoapsis
                358,     //Target heading
                115,    //max pitch drop
                50000,  //scale altitude
                1.1,    //curvature
                50).    //time to apoapsis throttleback
    doShutdown().//from vertLaunchUtils.lib.ks
    print "ascent complete, coasting to 70km altitude" at (0,10).
    lock steering to prograde.
    wait until ship:STATUS = "SUB_ORBITAL".
    //circularize orbit
    print "circularizing orbit...".
    doCircularization().//from orbitalMnvUtils.lib.ks
}

function performOrbitalMission {
    local partTags is list("main transmitter", "main boom", "main scanner").
    local antennaPart is ship:PARTSTAGGED(partTags[0])[0].
    local magboomPart is ship:PARTSTAGGED(partTags[1])[0].
    local scannerPart is ship:PARTSTAGGED(partTags[2])[0].
    local antennaModule is antennaPart:GETMODULE("ModuleDeployableAntenna").
    local magboomModule is magboomPart:GETMODULE("Experiment").
    local scannerModule is scannerPart:GETMODULE("SCANsat").
    print "Orienting spacecraft to face the planet".
    lock steering to heading(360, -90).
    if antennaModule:HASEVENT("extend antenna") {
        print "Extending the main antenna".
        antennaModule:DOEVENT("extend antenna").
    }
    if magboomModule:HASEVENT(
        "<b>magnetometer report</b>: <color=#ffd200>stopped</color>") {
            print "Deploying the magnetometer boom".
            magboomModule:DOEVENT(
                "<b>magnetometer report</b>: <color=#ffd200>stopped</color>").
        }
    if scannerModule:HASEVENT("start scan: radar") {
        print "Starting the radar altimetry scan".
        scannerModule:DOEVENT("start scan: radar").
    }
    until false {wait 1.}
}

main().