## cleanup.sh

This executable is a shell script written in BASH. It starts scanning from:

    /data/ftproot

The script scans recursively from there, skipping a few defined directories
and filenames. For every file found it checks if that file has been modified
more than 90 days ago. If it has, it moves the file to the temporary garbage
directory:

    /data/ftproot/.garbage/{year-month-day}/

It then writes the details, `ls -lh` to a log file created at:

    /data/ftproot/.bin/logs/{year-month-day-hour-minute-second}.log

I manually delete folders containing moved files in the garbage directory
every couple months or so after they have been moved there, provided
clients haven't request I restore them in the meantime.