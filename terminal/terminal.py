import os
import re
import sys
import getopt
import shutil
import uuid

ScriptName = None
AliasPath  = None

# ------------------------------------------------------------------

def printUsage(script):

    usage = '''
 NAME
        {script}

 DESCRIPTION
        Configure local settings.json file for windows terminal

 OPTIONS

        -h
        --help    Print this help page
                                                        
'''
    print(usage.format(script=script))

# ------------------------------------------------------------------

def insertLocalSettings(tmpfile, local, pattern):

  localStr = []
  if local != "":
    with open(local) as inputFile:
      for line in inputFile:
        # Ignore comment lines
        if re.search(r'^\s*//', line):
          continue
        localStr.append(line)

  combined = []
  with open(tmpfile) as tmp:
    for line in tmp:
      if re.search(r'^\s*//\s*' + pattern, line):
        combined.extend(localStr)
      else:
        combined.append(line)

  return combined


# ------------------------------------------------------------------

# ------------------------------------------------------------------

def createSettingsFile(settingsFile, localSettings, elkVersion, elasticPath, kibanaPath):

  global scriptPath

  newFile = scriptPath + r"\settings.json.generated"
  # tmpFile = scriptPath + r"\settings.tmp"

  # shutil.copyfile(settingsFile, tmpFile)

  elkPattern     = '_ELK_VERSION_'
  elasticPattern = '_ELASTIC_BIN_PATH_'
  kibanaPattern  = '_KIBANA_BIN_PATH_'
  guidPattern    = '_GUID_'
  guidDefPattern = '_GUID_DEFAULT_'

  GUID_DEF = str(uuid.uuid4())

  localSettingsPattern = 'LOCAL_SETTINGS'
  filelist = insertLocalSettings(settingsFile, localSettings, localSettingsPattern)

  with open(newFile, mode="w") as new:
    for l in filelist:

      if re.search(elkPattern, l):
        l = l.replace(elkPattern, elkVersion)

      elif re.search(elasticPattern, l):
        l = l.replace(elasticPattern, elasticPath)

      elif re.search(kibanaPattern, l):
        l = l.replace(kibanaPattern, kibanaPath)

      elif re.search(guidDefPattern, l):
        l = l.replace(guidDefPattern, GUID_DEF)

      elif re.search(guidPattern, l):
        newguid = str(uuid.uuid4())
        l = l.replace(guidPattern, newguid)

      new.write(l)

  print(f"Created new settings.json file : {newFile}")

# ------------------------------------------------------------------

###  ========================   MAIN  ========================   ###

def main(argv):

  global ScriptName
  global scriptPath

  scriptPath = os.path.dirname(os.path.realpath(__file__))
  localSettings = scriptPath + r'\settings.local'  

  Short_Options = 'f:h'
  Long_Options = ['file=', 'help']

  try:
    opts, args = getopt.gnu_getopt(argv, Short_Options, Long_Options)
  except getopt.GetoptError as err:
    print("Error processing arguments : " + str(err))
    print("Use -h(elp) to see further help")
    sys.exit(1)

  inputFile = None  
  for opt, arg in opts:  
    if opt == "-f":
      inputFile = arg
      if not os.path.isfile(inputFile):
        print(f"Input file {inputFile} not found!")
        sys.exit(1)  
      elif opt in ("-h", "--help"):
        printUsage(ScriptName)
        sys.exit(0)  
  if inputFile is None:
    inputFile = scriptPath + r'\settings.json'

  if not os.path.isfile(inputFile):
    print(f"No input file found. Tried {inputFile}")
    sys.exit(1)

  # If there is no local settings file, pass in an empty string below
  if not os.path.isfile(localSettings):
    localSettings = ""

  elkVersion = os.environ.get('ELK_VERSION')
  elasticPath = os.environ.get('ELASTIC_HOME')
  kibanaPath = os.environ.get('KIBANA_HOME')

  if elkVersion is None:
    print("ELK_VERSION is not set")
    sys.exit(1)
  elif elasticPath is None:
    print("ELASTIC_HOME is not set")
    sys.exit(1)
  elif kibanaPath is None:
    print("KIBANA_HOME is not set")
    sys.exit(1)

  elasticPath += '/bin'
  kibanaPath += '/bin'
  print()
  print(f"ELK Version : {elkVersion}\n"
        f"Elastic Path: {elasticPath}\n"
        f"Kibana Path : {kibanaPath}\n")
  
  createSettingsFile(inputFile, localSettings, elkVersion, elasticPath, kibanaPath)

  sys.exit(0)


# ==================================================================
ScriptName = sys.argv[0]
if __name__ == "__main__":
    main(sys.argv[1:])
