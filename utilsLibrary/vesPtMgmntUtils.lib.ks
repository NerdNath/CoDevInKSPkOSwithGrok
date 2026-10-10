//This library contains functions used in management of parts, partmodules,
//and actions/events of parts on vessels

//Prints the names of all the parts in the vessel out in the terminal.
function printAllPartnamesOnVessel {
    for part in ship:PARTS {
        print part:NAME.
    }
}

//Prints the titles (as they appear in the game) of all the parts in the vessel
//out in the terminal.
function printAllPartTitlesOnVessel {
    for part in ship:PARTS {
        print part:TITLE.
    }
}

//Prints the tags ("name tag" in the game) of any parts on the vessel that have
//been set by the player
function printAllPartTagsOnVessel {
    for part in ship:PARTS {
        print part:TAG.
    }
}

//Takes a part as a parameter, and prints a tree showing all the partmodules and
//the possible actions inside those modules, in the terminal
function printModulesAndActions {
    parameter tgtPart.
    for module in tgtPart:MODULES {
        print module.
        print tgtPart:GETMODULE(module):ALLACTIONNAMES.
    }
}

//Takes a part as a parameter, and prints a tree showing all the partmodules an
//the possible events inside those modules, in the terminal
function printModulesAndEvents {
    parameter tgtPart.
    for module in tgtPart:MODULES {
        print module.
        print tgtPart:GETMODULE(module):ALLEVENTNAMES.
    }
}

//Takes a string. Searches the current vessel for a part with a tag
//matching that string and then returns the part object of the first one
//in the vessel that has the tag. If none exists, prints a message to the
//terminal about it and returns false
function getPartFromTag {
    parameter tagString.
    set myPart to ship:PARTSTAGGED(tagString).
    if myPart:LENGTH > 0 {
        return myPart[0].
    }
    else {
        print "Attempted to get part tagged: " + tagString.
        print "but no part on the vessel has that tag".
        return false.
    }
}

//Takes a string. Searches the current vessel for a part with a name
//matching that string, then returns the part object.
function getPartFromName {
    parameter nameString.
    for part in ship:PARTS {
        if part:NAME = nameString {
            return part.
        }
    }
}

//Takes a part as a parameter, and logs a tree showing all the partmodules an
//the possible events inside those modules, in a log file
function logModulesAndEvents {
    parameter tgtPart.
    for module in tgtPart:MODULES {
        log module to partModulesPlusEvents.txt.
        log tgtPart:GETMODULE(module):ALLEVENTNAMES to partModulesPlusEvents.txt.
    }
}

//Takes two parameters: a part tag string, and an action/event string. Calls
//other function to get the first part on the vessel with that tag if multiple
//exist.  If none, a message is printed and the function ends. If one is found
//it checks whether any of the modules of that part have an event matching the
//action/event string. If one is found, it does the event. If not, it prints an
//error message and the function ends
function attemptEventOnTagged {
    parameter tagString, eventString.
    local taggedPart is getPartFromTag(tagString).
    local foundEvent is false.
    if taggedPart:TYPENAME = "Part" {
        for mod in taggedPart:MODULES {
            if taggedPart:GETMODULE(mod):HASEVENT(eventString) {
                taggedPart:GETMODULE(mod):DOEVENT(eventString).
                print "found & did " + eventString + " event in module: " + mod.
                set foundEvent to true.
                break.
            }
        }
        if foundEvent = false {
            print "Searched for event called " +eventString+ " in part ".
            print "tagged: " + tagString + ". Part was found, but that".
            print " event was not found on any of its modules".
        }
    }
}

//This function will loop through every module of every part on the active
//vessel, looking for an event with the name provided as a parameter. It will
//do the event every time it finds it.
function findAndDoAnyEvent {
    parameter eventString.
    for part in ship:PARTS {
        for mod in part:MODULES {
            if part:GETMODULE(mod):HASEVENT(eventString) {
                part:GETMODULE(mod):DOEVENT(eventString).
            }
        }
    }
}