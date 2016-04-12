#!/usr/bin/env bash

# A script that looks recursively from a starting directory (skipping certain named directories),
# and checks if found files are older than 90 days. Files meeting the conditions are moved to
# GARBAGE_DIR. The files that were moved are written to LOG_FILE in LOG_DIR.

GARBAGE_DIR="/data/ftproot/.garbage/$(date +%Y-%m-%d-%T)"
LOG_FILE="/data/ftproot/.bin/logs/$(date +%Y-%m-%d-%T).log"
LOG_DIR="/data/ftproot/.bin/logs"
ALL_RESULTS="/data/ftproot/.bin/results.txt"

# Create folders/files
[ -d $LOG_DIR ] || mkdir $LOG_DIR
[ -d "/data/ftproot/.garbage/" ] || mkdir "/data/ftproot/.garbage/"
mkdir $GARBAGE_DIR
touch $LOG_FILE
# Reset results.txt file, just a temp holding spot
[ -e $ALL_RESULTS ] && rm -f $ALL_RESULTS && touch $ALL_RESULTS || touch $ALL_RESULTS

echo ""
echo ""
echo "################################################################"
echo "              Scanner for files modified > 90 days ago          "
echo "################################################################"

# Ignore some matches (.garbage, common, .bin, users, .*) and write rest to file
# Since the each '-o' is an 'or', and each -prune expression returns false we keep
# processing until we hit a true expression, which is that last one, where we match
# all files remaining in the set and print to file.
find /data/ftproot \
     -iwholename "/data/ftproot/.garbage" -prune -o \
     -iwholename "/data/ftproot/common" -prune -o \
     -iwholename "/data/ftproot/.bin" -prune -o \
     -iwholename "/data/ftproot/users" -prune -o \
     -type f -iname '.*' -prune -o \
     -type f -fprint $ALL_RESULTS

# Give summary of what happened to the user
NUM_FILES=$(cat $ALL_RESULTS | wc -l)
echo "Search found $NUM_FILES total files."
echo "Moving files modified more than 90 days ago to the temporary garbage."
echo "Please wait..."

# Check each file if modified > 90 days ago, if yes move and append details to log
# BUGFIX: Display details first using 'ls', errors if we do the reverse.
# BUGFIX: If we get 'access denied' to a file it was spitting out to stdout and we
# could not write that to the logfile, so the logfile was cut short on first access
# denied message. Workaround is to swallow stderr to /dev/null in this case.
if [ -e $ALL_RESULTS ]; then
    while read RES_LINE; do
	if [ $(date +%s -r "$RES_LINE") -lt $(date +%s --date="90 days ago") ]; then
	    ls -lh "$RES_LINE" | tee -a $LOG_FILE
	    mv "$RES_LINE" "$GARBAGE_DIR" 2>/dev/null
	fi
    done < $ALL_RESULTS
else
    echo "ERROR: results.txt file could not be found in the current directory."
    exit
fi

# Tell user hwo much was moved and where
# BUGFIX: Totals were off when 0 files were moved because 'ls -l' will report 1
# even if directory empty. Workaround is to decrement it.
DIR_TOTAL=$(ls -l $GARBAGE_DIR | wc -l)
TOTAL_MOVED=`expr $DIR_TOTAL - 1`
echo "#####################################################################"
echo "Moved: $TOTAL_MOVED file(s) total."
echo "(If you see files listed above but the total is 0, it is because we "
echo "don't have permission to move those files)"
echo ""
echo "Files placed in: $GARBAGE_DIR"
echo "Details of files moved can be found in: $LOG_FILE"
echo "Done."
echo "#####################################################################"
echo ""
echo ""
exit
