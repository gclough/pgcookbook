#!/bin/bash

# terminate_activity.sh - activity watchdog and terminator.
#
# Constantly performs server activity checks with TERMINATE_DELAY
# seconds those checks and terminates sessions that comply to
# TERMINATE_CONDITIONS. The script was made for running as a cron job
# and exits normally if another instance is running with the same
# TERMINATE_PID_FILE. If TERMINATE_STOP_FILE exists it does not
# perform any operations.
#
# Copyright (c) 2014 Sergey Konoplev
#
# Sergey Konoplev <gray.ru@gmail.com>

source $(dirname $0)/config.sh
source $(dirname $0)/utils.sh

(
    flock -xn 543 || exit 0
    trap "rm -f $TERMINATE_PID_FILE" EXIT
    echo $BASHPID >$TERMINATE_PID_FILE

    while [ ! -f $TERMINATE_STOP_FILE ]; do
        $PSQL -XAtx -F ': ' -c \
            "SELECT \
                pg_terminate_backend(pid), \
                now() - xact_start AS xact_duration, * \
             FROM pg_stat_activity \
             WHERE $TERMINATE_CONDITIONS"

        sleep $TERMINATE_DELAY
    done

    die "Stop file exists, remove it first."
) 543>>$TERMINATE_PID_FILE
