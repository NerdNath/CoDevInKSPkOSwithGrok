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
        else if ship:STATUS = "ORBITING"
        and ship:BODY:NAME = "Kerbin"
        and ship:ORBIT:APOAPSIS < 90000 {
            print "In trans munar injection mission:".
            planAndExecuteTransMunarInjection().
        }
        else if ship:ORBIT:HASNEXTPATCH
        and ship:BODY:NAME = "Kerbin"
        and MISSIONTIME < 20000 {
            print "In coast to Mun encounter phase: ".
            doCoastPhase().
        }
        else if ship:BODY:NAME = "Mun"
        and ship:STATUS = "ESCAPING" {
            print "In munar flyby mission:".
            performMunarFlybyMission().
        }
        else if ship:STATUS = "ORBITING" or ship:STATUS = "SUB_ORBITAL"
        and ship:BODY:NAME = "Kerbin"
        and ship:ORBIT:APOAPSIS >= 90000
        and MISSIONTIME > 20000 {
            print "In return mission phase:".
            doReturnMission().
        }
        else if ship:STATUS = "FLYING"{
            print "In reEntry and landing mission phase:".
            doReEntryAndLanding().
        }
        else if ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED" {
            wait 3.
            print "Mission appears to be complete. Program terminating".
            break.
        }
    }
}

function launchToOrbit {
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   80000,      //Target apoapsis
                90,         //Target heading
                115,         //max pitch drop
                50000,      //scale altitude
                1.1).      //curvature
    doShutdown().//from vertLaunchUtils.lib.ks
    print "ascent complete, coasting to 70km altitude" at (0,10).
    lock steering to prograde.
    wait until ship:STATUS = "SUB_ORBITAL".
    //circularize orbit
    print "circularizing orbit...".
    doCircularization().//from orbitalMnvUtils.lib.ks
}

function planAndExecuteTransMunarInjection {
    print "planning trans munar injection.".
    planTMI().//from orbitalMnvUtils.lib.ks
    set myNode to list(nextNode:TIME, 0, 0, nextNode:PROGRADE).
    print "entering maneuver execution program".
    executeManeuver(myNode).//from orbitalMnvUtils.lib.ks
    print "trans munar injection program complete.".
    print "deploying antenna".
    set myPart to ship:PARTSTAGGED("main transmitter").
    if myPart[0]:GETMODULE(
        "ModuleDeployableAntenna"):HASEVENT("extend antenna") {
            myPart[0]:GETMODULE(
                "ModuleDeployableAntenna"):DOEVENT("extend antenna").
        }
}

function doCoastPhase {
    wait until ship:BODY = "Mun".
}

function performMunarFlybyMission {
    set myPart to ship:PARTSTAGGED("second goo").
    if myPart[0]:GETMODULE("Experiment"):HASEVENT(
        "<b>mystery goo™ observation</b>: <color=#ffd200>stopped</color>"
        ) {
            print "Activating second mystery goo...".
            myPart[0]:GETMODULE("Experiment"):DOEVENT(
                "<b>mystery goo™ observation</b>: <color=#ffd200>stopped</color>"
                ).
            print "Now waiting to escape from the Mun".
        }
    else if myPart[0]:GETMODULE("Experiment"):HASEVENT(
        "mystery goo™ observation: <color=#6dcff6>waiting</color>"
        ) {
            print "The goo experiment appears to be already completed".
            print "Now waiting to escape from the Mun".
        }
}

function doReturnMission{
    // until MISSIONTIME > ship:ORBIT:PERIOD {
    //     print "Completing one orbit around kerbin to avoid second mun encounter".
    //     wait until MISSIONTIME > ship:ORBIT:PERIOD.
    // }
    if ship:STATUS = "ORBITING" {
        print "planning and executing a deorbit burn at apoapsis".
        set apoapsisTime to time:SECONDS + ship:ORBIT:ETA:APOAPSIS.
        set mnvValues to list(apoapsisTime, 0, 0, -(ship:DELTAV:CURRENT)).
        executeManeuver(mnvValues).
        doCollisionDeorbit().
        lock steering to up.
        wait 3.
        print "Jettisoning 2nd stage...".
        doSafeStage(). //from vertLaunchUtils.lib.ks
    }
    wait 1.
    lock steering to retrograde.
    print "waiting for reentry interface to begin".
    wait until ship:STATUS = "FLYING".
}

function doReEntryAndLanding{
    lock steering to retrograde.
    print "retracting antenna...".
    set myPart to ship:PARTSTAGGED("main transmitter").
    if myPart[0]:GETMODULE(
        "ModuleDeployableAntenna"):HASEVENT("retract antenna") {
            myPart[0]:GETMODULE(
                "ModuleDeployableAntenna"):DOEVENT("retract antenna").
        }
    wait until ship:ALTITUDE < 15000.
    print "deploying parachute...".
    wait 1.
    set myPart to ship:PARTSTAGGED("main chute").
    if myPart[0]:GETMODULE("ModuleParachute"):HASEVENT("deploy chute") {
        myPart[0]:GETMODULE("ModuleParachute"):DOEVENT("deploy chute").
    }
    unlock steering.
    wait until ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED".
    print "Touchdown...".
}

main().