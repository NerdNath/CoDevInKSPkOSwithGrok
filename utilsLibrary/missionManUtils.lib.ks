//This library contains functions used by scripts to manage the mission of a
//vessel

//This function takes a key and a value assumed in the format for a lexicon.
//It then checks to see if the current vessel has a missionMemory JSON file
//on the root volume, and if it doesn't it does nothing and prints a message
//to inform the user that it was called when there was no missionMemory file
//When a mission memory file is present, it then reads it, and checks to see
//if the provided key exists in the file. If it does, it updates that key by
//storing the provided value into it. If the mission file does not contain the
//provided key, it then adds the key, also assigning the provided value there
function updateMissionMem {
    parameter providedKey, providedValue.
    if core:VOLUME:FILES:HASKEY("missionMemory.json") {
        local retrievedLex is readJson("missionMemory.json").
        local updatedLex is lexicon().
        set updatedLex to retrievedLex.
        if not(retrievedLex:HASKEY(providedKey)) {
            updatedLex:ADD(providedKey, providedValue).
        }
        else {
            set updatedLex[providedKey] to providedValue.
        }
        writeJson(updatedLex, "missionMemory.json").
    }
    else {
        print "updateMissionMem function was called when the current vessel
        does not have a missionMemory.json file store on it. Mission memory
        will therefore not be updated.".
    }
}