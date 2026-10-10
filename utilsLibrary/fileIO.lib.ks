//fileIO.lib.ks
//Library of kerbal file system check functions

function fileContentsMatch {
  //the following parameters must both be an absolute
  //path to a file in the form of a string
  //(.text, .csv, .ks file, or .ksm file are supported)
  parameter subjectFile.
  parameter targetFile.
  if open(subjectFile):READALL:STRING = open(targetFile):READALL:STRING {
    return true.
  } else {
    return false.
  }
}

function isPathEmpty {
  //the following parameter must be a valid path
  //in the form of a string
  parameter subjectPath.

  set pathStructure to open(subjectPath).
  if pathStructure:SIZE = 0 {
    return true.
  }
  else {
    return false.
  }
}

function createScriptOnlyFileList {
  parameter volumeToListFrom is 0.//so far only known to support cpu core ("1:/")
                                  //or the archive ("0:/"). Therefore, this
                                  //is a boolean that picks between the two
  if volumeToListFrom = 0 {
    switch to 0.
  } else switch to 1.
  list files in startList.
  set finishedList to list().
  for entry in startList {
    if entry:EXTENSION = "ks" {
      finishedList:ADD(entry).
    }
  }
  return finishedList.
}

function scriptLoad {
  parameter scriptString.
  copypath("0:/" + scriptString, "1:/").
}

// TODO: make this list logging function
// function logListOut {
//   parameter theList.
//   parameter logFilePath.

//   for listEntry in theList {
//     log 
//   }
// }