//This is the script for the EEG 1 relay satellite.

// clearscreen.
//include the needed library scripts
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "virdestLibrary/".
    local neededLibaries is list(
        "vertLaunchUtils.lib.ks",
        "orbitalMnvUtils.lib.ks",
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

function main {
    until false {
        if ship:STATUS = "PRELAUNCH" {
            launchToOrbit().
        }
        else if ship:STATUS = "ORBITING"{
            print "In orbital mission phase.".
            // until false {wait 1.}
            doOrbitalMission().
            print "Orbital mission appears complete. Program will now end.".
            break.
        }
    //     else if ship:STATUS = "SUB_ORBITAL" or ship:STATUS = "FLYING" {
    //         print "In reEntry and Landing mission phase.".
    //         doReEntryAndLanding().
    //     }
    //     else if ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED" {
    //         print "Mission appears to be complete. Program terminating.".
    //     }
    }
}

function launchToOrbit {
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   6047000,    //Target apoapsis
                90,         //Target heading
                90,         //max pitch drop
                65000,      //scale altitude
                0.7,        //curvature
                70).        //maximum eta to apoapsis
    doShutdown().//from vertLaunchUtils.lib.ks
    print "ascent complete, coasting to 70km altitude" at (0,10).
    lock steering to prograde.
    if ship:STATUS = "FLYING" {wait until ship:STATUS = "SUB_ORBITAL".}
    deployAntenna().
    //circularize orbit
    doCircularization().//from orbitalMnvUtils.lib.ks
}

function doOrbitalMission {
    // set myNode to list(nextNode:TIME, 
    //                     0, 
    //                     0, 
    //                     nextNode:PROGRADE).
    // executeManeuver(myNode).
}

function doReEntryAndLanding {
    print "holding steering on prograde because heatshield is on the front".
    lock steering to prograde.
    wait until ship:altitude < 15000.
    print "deploying chute".
    attemptEventOnTagged("main chute", "deploy chute").//from vesPtMgmtUtils
    unlock steering.
    wait until ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED".
}

function deployAntenna {
    print "deploying antenna".
    attemptEventOnTagged("main transmitter", "extend antenna").
}

main().