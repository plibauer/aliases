import os
import re
import sys
import getopt
import configparser

ScriptName = None

# ------------------------------------------------------------------


def printUsage(script):

    usage = '''
 NAME
        {script}

 DESCRIPTION
        Setup a shell environment for a given release (Eg. 9.2 or 92)

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


def template(script, config, home, release, prefix, folder, arch, compiler, build, idol, elastic):

    template = f'''
# Generated from script : {script}
# Configuration file    : {config}

unalias '*'
unset var_*

set alias_dir         = {home}/tcsh
set revision          = {release}
set default_dbid_pref = {prefix}
set default_dbid      = $default_dbid_pref"1"
set folder            = {folder}
set defArch           = {arch}
set defCompiler       = {compiler}
set defBuild          = {build}
set defPatch          = 
set idolDbPrefix      = {idol}
set elasticDbPrefix   = {elastic}

source $alias_dir/aliases_local.txt
source $alias_dir/aliases
source $alias_dir/aliases_common.txt

settitle

'''
    return template


# ------------------------------------------------------------------
'''  ========================   MAIN  ========================   '''


def main(argv):

    numberOfArgs = len(argv)
    Short_Options = 'a:b:c:e:f:hi:p:r:'
    Long_Options = ['config=', 'help']

    try:
        opts, args = getopt.gnu_getopt(argv, Short_Options, Long_Options)
    except getopt.GetoptError as err:
        print("Error processing arguments : " + str(err))
        print("Use -h(elp) to see further help")
        sys.exit(1)

    alias_dir = arch = build = compiler = configFile = elastic = folder =\
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
    if configFile is None:
        configFile = 'make_env.config'

    if not os.path.isfile(configFile):
        print(
            f"Configuration file {configFile} not found! (are you in the right directory?)")
        sys.exit(1)

    config.read(configFile)

    # If no release version specified but there are unprocessed command line options,
    # assume the first available option is the release version
    if release is None:
        if len(args) > 0:
            release = args[0]
        else:
            release = input("Specify the release version \(Eg. 9.2\) : ")

    release = release.replace(".", "")
    if re.search(r'^\d{2}$', release):
        if release not in config:
            print(
                f"Release {release} not found in configuration file {configFile}")
            sys.exit(1)
    else:
        print(f"Invalid release version {release} (expect \d.\d or \d{{2}})")
        sys.exit(1)

    alias_dir = config.get('DEFAULT', 'alias_directory')

    if arch is None:
        arch = config.get('DEFAULT', 'architecture')

    if build is None:
        build = config.get('DEFAULT', 'build')

    if compiler is None:
        if 'compiler' in config[release]:
            compiler = config.get(release, 'compiler')
        else:
            compiler = config.get('DEFAULT', 'compiler')

    if elastic is None:
        # Elastic is only valid from 93 onwards
        if int(release) > 92:
            if 'elastic_prefix' in config[release]:
                elastic = config.get(release, 'elastic_prefix')
            else:
                elastic = config.get('DEFAULT', 'elastic_prefix')
        else:
            elastic = ""

    if folder is None:
        if 'folder' in config[release]:
            folder = config.get(release, 'folder')
        else:
            folder = "$revision"

    if idol is None:
        if 'idol_prefix' in config[release]:
            idol = config.get(release, 'idol_prefix')
        else:
            idol = config.get('DEFAULT', 'idol_prefix')

    if prefix is None:
        prefix = config.get(release, 'prefix')

    temp = template(ScriptName, configFile, alias_dir, release, prefix, folder,	arch, compiler,
                    build, idol, elastic)
    print(temp)

    sys.exit(0)


# ==================================================================
ScriptName = sys.argv[0]
if __name__ == "__main__":
    main(sys.argv[1:])
