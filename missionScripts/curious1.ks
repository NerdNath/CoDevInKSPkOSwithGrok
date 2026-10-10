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
            planAndExecuteTransMunarInjection().
        }
        else if ship:BODY = "Mun" {
            performMunarFlybyMission().
        }
        else if ship:STATUS = "ORBITING"
        and ship:BODY:NAME = "Kerbin"
        and ship:ORBIT:APOAPSIS >= 90000 {
            doReturnMission().
        }
        else if ship:STATUS = "FLYING"{
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
    doAscent(   50000,  //Target apoapsis
                90,     //Target heading
                115,    //max pitch drop
                50000,  //scale altitude
                1.1,    //curvature
                25).    //max ETA to apoapsis (controls throttleback)
    doShutdown().//from vertLaunchUtils.lib.ks
    // print "ascent complete, coasting to 70km altitude" at (0,10).
    // lock steering to prograde.
    // wait until ship:STATUS = "SUB_ORBITAL".
    // //circularize orbit
    // print "circularizing orbit...".
    // doCircularization().//from orbitalMnvUtils.lib.ks
}

function planAndExecuteTransMunarInjection {
    print "planning trans munar injection.".
    planTMI().
    set myNode to list(nextNode:TIME, 0, 0, nextNode:PROGRADE).
    print "entering maneuver execution program".
    executeManeuver(myNode).
    print "trans munar injection program complete.".
    print "deploying antenna".
    set myPart to ship:PARTSTAGGED("main transmitter").
    myPart:GETMODULE("ModuleDeployableAntenna"):DOEVENT("extend antenna").
}

function performMunarFlybyMission {
    print "Activating second mystery goo...".
    set myPart to ship:PARTSTAGGED("second goo").
    if myPart[0]:GETMODULE("Experiment"):HASEVENT(
        "<b>mystery goo™ observation</b>: <color=#ffd200>stopped</color>"
        ) {
            myPart[0]:GETMODULE("Experiment"):DOEVENT(
                "<b>mystery goo™ observation</b>: <color=#ffd200>stopped</color>"
                ).
        }
    else print "There was a problem with the goo experiment".
}

function doReturnMission{
    until MISSIONTIME > ship:ORBIT:PERIOD {
        print "Completing one orbit around kerbin to avoid second mun encounter".
        wait until MISSIONTIME > ship:ORBIT:PERIOD.
    }
    print "planning and executing a deorbit burn at apoapsis".
    set apoapsisTime to time:SECONDS + ship:ORBIT:ETA:APOAPSIS.
    set mnvValues to list(apoapsisTime, 0, 0, -ship:DELTAV:CURRENT).
    executeManeuver(mnvValues).
    lock steering to up.
    wait 3.
    print "Jettisoning 2nd stage...".
    doSafeStage(). //from vertLaunchUtils.lib.ks
    wait 1.
    lock steering to retrograde.
    print "waiting for reentry interface to begin".
    wait until ship:STATUS = "FLYING".
}

function doReEntryAndLanding{
    lock steering to retrograde.
    wait until ship:ALTITUDE < 15000.
    print "deploying parachute...".
    wait 1.
    set myPart to ship:PARTSTAGGED("main chute").
    myPart[0]:GETMODULE("ModuleParachute"):DOEVENT("deploy chute").
    unlock steering.
    print "jettisoning heat shield...".
    wait 1.
    set myPart to ship:PARTSTAGGED("main heatshield").
    myPart[0]:GETMODULE("ModuleDecouple"):DOEVENT("jettison heat shield").
    wait until ship:STATUS = "LANDED" or "SPLASHED".
    print "Touchdown...".
}

main().