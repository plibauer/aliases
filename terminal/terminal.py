import os
import re
import sys
import getopt
import shutil

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
# ------------------------------------------------------------------

def writeFile(inputFile, localSettings, elkVersion):

	newFile = "settings.json.generated"
	f = open(newFile, "w")
	f.write("Something done")
	f.close()
	print(f"Created settings.json file : {newFile}")

# ------------------------------------------------------------------

###  ========================   MAIN  ========================   ###

def main(argv):

  global ConfigFile
  global ScriptName
  global AliasPath

  scriptPath = os.path.realpath(__file__)
  AliasPath = os.path.dirname(scriptPath)
  TerminalPath = AliasPath + r'\terminal'
  localSettings = TerminalPath + 'settings.local'  

  numberOfArgs = len(argv)
  Short_Options = 'f:h'
  Long_Options = ['file=', 'help']

  try:
    opts, args = getopt.gnu_getopt(argv, Short_Options, Long_Options)
  except getopt.GetoptError as err:
    print("Error processing arguments : " + str(err))
    print("Use -h(elp) to see further help")
    sys.exit(1)

  alias_dir = inputFile = localSettings = None  
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
    inputFile = AliasPath + r'\terminal\settings.json'

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

  elasticPath += r'\bin'
  kibanaPath += r'\bin'
  print(f"ELK Version: {elkVersion}, Elastic: {elasticPath}, Kibana: {kibanaPath}")  
  sys.exit(0)


# ==================================================================
ScriptName = sys.argv[0]
if __name__ == "__main__":
    main(sys.argv[1:])
