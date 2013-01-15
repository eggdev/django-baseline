#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(dirname $0)
[ "${SCRIPT_DIR}" == "." ] && SCRIPT_DIR=$(pwd)

# make sure we're in the project directory
cd "${SCRIPT_DIR}"

PROJECT="baseline"
LOCALSETTINGS="$PROJECT/local_settings.py"

VENV="venv"
PIP="$VENV/bin/pip"
PYTHON="$VENV/bin/python"
ACTIVATE="$VENV/bin/activate"

function find_pyc {
    find ${SCRIPT_DIR} -path ${SCRIPT_DIR}/venv -prune -o -type f -name '*.pyc' -print
}

echo "Baseline Bootstrap v1.0"
echo "-----------------------"
echo

if [ "$1" == "-h" -o "$1" == "help" -o "$1" == "-?" ]; then
	echo "When run without any arguments, this script sets up the chefpa project"
	echo "for running using a virtualenv in the current working directory."
	echo
	echo "The NOINPUT environment variable can be set to '1' (anything not "
	echo "empty, really) in order to run without prompting.  Note: this can "
	echo "be dangerous when combined with clean / superclean"
	echo
	echo "Usage: $0 [-h|--noinput|clean|superclean]"
	echo
	echo "  help         display this help"
	echo "  clean        remove all .pyc files"
	echo "  superclean   remove all .pyc files, dev database, and virtualenv"
	echo
	exit
fi

if [ "$1" == "clean" ]; then
    echo "Files to delete:"
    find_pyc | sed 's/^/    /'

    if [ -z ${NOINPUT} ]; then
        echo
        echo -n "Are you sure? [y|N]: "

        read input
    else
        input='y'
    fi

	if [ "$input" == "y" -o "$input" == "Y" ]; then
		echo -n "deleting."
        find_pyc | xargs rm -f
		echo ".done"
	else
		echo "Aborting."
	fi
	exit
fi

if [ "$1" == "superclean" ]; then
	DEV_DB="db.sqlite3"

    if [ -z ${NOINPUT} ]; then
        echo "Files to delete:"
        [ -e "$DEV_DB" ]        && echo "    rm -rf $DEV_DB"
        [ -e "$LOCALSETTINGS" ] && echo "    rm -rf $LOCALSETTINGS"
        [ -e "$VENV" ]          && echo "    rm -rf $VENV/"
        echo
        find_pyc | sed 's/^/    /'
        echo
        echo -n "Are you sure? [y|N]: "

        read input
    else
        input='y'
	fi;

	if [ "$input" == "y" -o "$input" == "Y" ]; then
		echo -n "deleting."

		[ -e "$DEV_DB" ]        && rm -rf "$DEV_DB"        && echo -n "."
		[ -e "$VENV" ]          && rm -rf "$VENV/"         && echo -n "."
		[ -e "$LOCALSETTINGS" ] && rm -rf "$LOCALSETTINGS" && echo -n "."
        find_pyc | xargs rm -f
		echo ".done"
	else
		echo "Aborting."
	fi
	exit
fi

# create the virtual environment
if [ ! -e "$VENV" ]; then
	virtualenv "$VENV" --distribute
fi;

# install requirements, always install in order to update an existing venv
${PIP} install -r requirements.txt

# create localsettings module
if [ ! -e ${LOCALSETTINGS} ]; then
	echo 'from conf.settings.development import *' >> ${LOCALSETTINGS}
fi;

got_secret_key=$(grep SECRET_KEY ${LOCALSETTINGS})
if [ "$?" -ne "0" ]; then
	${PYTHON} manage.py secretkey
else
	echo "Got SECRET_KEY"
fi;

if [ ! -z ${NOINPUT} ]; then
    manage_args="--noinput"
else
    manage_args=""
fi;

# sync the local database
${PYTHON} manage.py syncdb $manage_args
${PYTHON} manage.py migrate $manage_args

echo
echo "--------------------------------------------"
echo
echo "Done! Don't forget to active the virtualenv:"
echo "    $ source $ACTIVATE"
echo
