import os
import re
import sys
import getopt
import configparser
import shutil

ScriptName = None
ConfigFile = None
AliasPath  = None

# ------------------------------------------------------------------


def printUsage(script):

    usage = '''
 NAME
        {script}

 DESCRIPTION
        Setup a shell environment for a given release (Eg. 9.2 or 92). Without any arguments,
        the script will look for the file make_env.config in the local directory and 
        process all the entries it finds.

 OPTIONS

		-a <architecture>
			Eg. x64 or x86
		
		-b <build>
		    Eg. Debug or Release
			
		-c <compiler>
			Eg. VS2013 or VS2015 or VS2017 etc.
		
		--config <config file path>
			Speficy the path to the configuration file (Default is [PYTHON_HOME]/make_env.config)
			
		-e <elastic prefix>
			Eg. CM_
			
		-f <folder path>
			Eg. 'trunk' when the revision is the latest branch, otherwise
			aliases will expect that the folder name is the same as the revision
			number. Also, if a checkout was to C:/9.3 for example, then the 
			'folder' value should be specified as 9.3 because by default it will
			expect the checkout folder to be '93'

		-h
        --help
            Print this help page
			
		-i <idol prefix>
			Eg. HPERM_ or CM_
			
		-p <prefix>
			Eg, K, J, L, M, ....
			
		-r <release version>
			Eg, 83, 8.3, 90, 91 etc.
			
 EXAMPLES

        1. Configure settings for release version 9.2
                {script} -r 9.2


		2. Specify all values on command line
				{script} -a x64 -b Debug -c VS2017 -e CM_ -f trunk -i CM_ -p M -r 9.4
				
'''
    print(usage.format(script=script))

# ------------------------------------------------------------------
# ------------------------------------------------------------------
# ------------------------------------------------------------------
# ------------------------------------------------------------------
# ------------------------------------------------------------------


def template(home, release, prefix, folder, arch, compiler, build, idol, elastic):

    global ScriptName
    global ConfigFile
    
    template = f'''
# Generated from script : {ScriptName}
# Configuration file    : {ConfigFile}

unset var_*
unset env_*

set env_alias             = {home}
set env_alias_dir         = $env_alias/tcsh
set env_revision          = {release}
set env_default_dbid_pref = {prefix}
set env_default_dbid      = $env_default_dbid_pref"1"
set env_folder            = {folder}
set env_defArch           = {arch}
set env_defCompiler       = {compiler}
set env_defBuild          = {build}
set env_idolDbPrefix      = {idol}
set env_elasticDbPrefix   = {elastic}

source $env_alias_dir/LOCAL.txt
source $env_alias_dir/include.txt

settitle

'''
    return template


# ------------------------------------------------------------------

def writeFile(config, rev, arch, build, compiler, elastic, folder, idol, prefix):

    alias_dir = config.get('DEFAULT', 'alias_directory')

    if arch is None:
        if 'architecture' in config[rev]:
            arch = config.get(rev, 'architecture')
        else :
            arch = config.get('DEFAULT', 'architecture')

    if build is None:
        if 'build' in config[rev]:
            build = config.get(rev, 'build')
        else :
            build = config.get('DEFAULT', 'build')


    if compiler is None:
        compiler = config.get(rev, 'compiler')

    if elastic is None:
        # Elastic is only valid from 93 onwards
        if int(rev) > 92:
            if 'elastic_prefix' in config[rev]:
                elastic = config.get(rev, 'elastic_prefix')
            else:
                elastic = config.get('DEFAULT', 'elastic_prefix')
        else:
            elastic = ""

    if folder is None:
        if 'folder' in config[rev]:
            folder = config.get(rev, 'folder')
        else:
            folder = "$env_revision"

    if idol is None:
        if 'idol_prefix' in config[rev]:
            idol = config.get(rev, 'idol_prefix')
        else:
            idol = config.get('DEFAULT', 'idol_prefix')

    if prefix is None:
        prefix = config.get(rev, 'prefix')

    temp = template(alias_dir, rev, prefix, folder,	arch, compiler,
                    build, idol, elastic)


    f = open(AliasPath + f"/{rev}environment", "w")
    f.write(temp)
    f.close()
    print(f"Created environment file : {AliasPath}\{rev}environment")

# ------------------------------------------------------------------

###  ========================   MAIN  ========================   ###


def main(argv):

    global ConfigFile
    global ScriptName
    global AliasPath

    scriptPath = os.path.realpath(__file__)
    AliasPath = os.path.dirname(scriptPath)

    numberOfArgs = len(argv)
    Short_Options = 'a:b:c:e:f:hi:p:r:'
    Long_Options = ['config=', 'help']

    try:
        opts, args = getopt.gnu_getopt(argv, Short_Options, Long_Options)
    except getopt.GetoptError as err:
        print("Error processing arguments : " + str(err))
        print("Use -h(elp) to see further help")
        sys.exit(1)

    alias_dir = arch = build = compiler = elastic = folder =\
        idol = prefix = release = None

    for opt, arg in opts:

        if opt == "-a":
            arch = arg
            if arch not in ("x86", "x64"):
                print(f"Invalid input for architecture - expected one of 'x86' or 'x64'")
                sys.exit(1)

        elif opt == "-b":
            build = arg.lower().capitalize()
            if build not in ("Release", "Debug"):
                print(f"Invalid input for build - expected one of 'Debug' or 'Release'")
                sys.exit(1)

        elif opt == "-c":
            compiler = arg

        elif opt == "--config":
            configFile = arg

        elif opt == "-e":
            elastic = arg
            if not re.search(r'^\w+$', elastic):
                print(
                    "Invalid string for elastic prefix - must match : [a-Z_]+")
                sys.exit(1)

        elif opt == "-f":
            folder = arg

        elif opt in ("-h", "--help"):
            printUsage(ScriptName)
            sys.exit(0)

        elif opt == "-i":
            idol = arg

        elif opt == "-p":
            prefix = arg

        elif opt == "-r":
            release = arg

    config = configparser.ConfigParser()
    if ConfigFile is None:
        ConfigFile = AliasPath + '\make_env.config'

    if not os.path.isfile(ConfigFile):
        print(
            f"Configuration file {ConfigFile} not found! Tried => {AliasPath}")
        sys.exit(1)

    config.read(ConfigFile)

    configs2process = []
    # If no arguments were provided, process all entries in the configuration file
    if (release is None) and (len(args) == 0):
        for item in config:
            if item == "DEFAULT" :
                next
            if re.search(r'^\d{2,3}$', item):
                configs2process.append(item)

    else :
        # If no release version specified but there are unprocessed command line options,
        # assume the first available option is the release version
        if len(args) > 0:
            release = args[0]

        else:
            release = input("Specify the release version \(Eg. 9.2\) : ")

        release = release.replace(".", "")
        if re.search(r'^\d{2,3}$', release):
            if release not in config:
                print(
                    f"Release {release} not found in configuration file {configFile}")
                sys.exit(1)
        else:
            print(f"Invalid release version {release} (expect \d.\d or \d{{2,3}})")
            sys.exit(1)

        configs2process.append(release)

        
    for rev in configs2process:
        writeFile(config, rev, arch, build, compiler, elastic, folder, idol, prefix)

    # Copy the DEFAULTS.txt file => LOCAL.txt
    defFile = "tcsh\DEFAULTS.txt"
    defPath = f"{AliasPath}\{defFile}"
    locFile = "tcsh\LOCAL.txt"
    locPath = f"{AliasPath}\{locFile}"
    print()
    if os.path.exists(defPath):

        # Try to preserve the existing LOCAL.txt file and also check for LOCAL.txt.bak
        if os.path.exists(locPath):
            if os.path.exists(f"{locPath}.bak"):
                txt = input(f"The backup file {locPath}.bak exists!\nOVERWRITE? [Y/n] : ")
                if re.search("^y(es)*$", txt, re.IGNORECASE):
                    shutil.copy2(locPath, f"{locPath}.bak")
                    print(f"*** Backed-up existing {locFile} => {locPath}.bak ***")
            else:
                shutil.copy2(locPath, f"{locPath}.bak")
                print(f"Backed-up existing {locFile} => {locPath}.bak ***")


        shutil.copy2(defPath, locPath)
        print(f"Copied {defFile} => {locFile}\n(!!! CHANGE !!! the parameters in {locFile} as required)")
    else:
        print(f"The file {defPath} was not found?")

    sys.exit(0)


# ==================================================================
ScriptName = sys.argv[0]
if __name__ == "__main__":
    main(sys.argv[1:])
