//This library contains functions used in automating career activities in the
//game such as accepting or completing contracts

//This function will loop through the available contracts looking for a part
//test contract that has all the conditions met, and then search the active
//vessel for a part matching that title and attempt to complete the test on it
//Depends on the career addon mod, and will print a message and not complete if
//it is missing
function searchAndCompletePartTest {
    local foundContract is false.
    local mycontract is false.
    local testGo is false.
    local metPsTotal is 0.//a counter to hold the amount of met parameters
    if addons:CAREER:AVAILABLE {
        local actvContracts to addons:CAREER:ACTIVECONTRACTS().
        if actvContracts:LENGTH > 0 {
            for contract in addons:CAREER:ACTIVECONTRACTS() {
                if contract:TITLE:CONTAINS("Test") {
                    set foundContract to true.
                    set mycontract to contract.
                }
            }
        }
        if foundContract {
            //all contract parameters stored in short variable:
            local allParams is mycontract:PARAMETERS.
            //the relevant parameters stored in a short variable:
            local rParams is allParams:SUBLIST(1, allParams:LENGTH -1).
            for param in rParams {
                if param:STATE = "Complete" {
                    set metPsTotal to metPsTotal + 1.
                }
            }
            if metPsTotal = rParams:LENGTH {
                set testGo to true.
            }
            if testGo {
                for part in ship:PARTS {
                    if mycontract:TITLE:CONTAINS(part:TITLE) {
                        for mod in part:MODULES {
                            if part:GETMODULE(mod):HASEVENT("run test") {
                                part:GETMODULE(mod):DOEVENT("run test").
                                break.
                            }
                        }
                        if mycontract:STATE = "Completed" {break.}
                        else if part:STAGE = ship:STAGENUM -1 {
                            wait until stage:READY.
                            stage.
                        }
                    }
                }
            }
        }
    }
    else {
        print "function searchAndCompletePartTest entered but the career addon
        mod for kOS is not installed, and it is necessary".
    }
}