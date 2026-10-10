//This script will look for a part with the tag given here, and then print out that
//part's partModules and their doable actions. You must name the part tag "target part"
//before running the script. If more than one part have that tag, this script will 
//only work on the first one in the part tree that it hits.

//include the needed library scripts
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "virdestLibrary/".
    local neededLibraries is list(
        "vesPtMgmtUtils.lib.ks"
    ).
    cd("1:/library").
    for lib in neededLibraries {
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

for part in ship:PARTS {
    if part:TAG = "target part" {
        printModulesAndActions(part).
    }
}