#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT
cd $(dirname $0)

#
# add SP fields to db
#  20191204WF  init

# sp_mean and sp_path are in schema.sql, but were not in actuall db
#   sqlite3 rest.db 'ALTER table rest add sp_mean float;ALTER table rest add sp__path text;'
cnt=1
sqlite3 rest.db 'select distinct ts4d from rest
    where sp_mean is null and
    ts4d not like "%snip%" and
    study not like "%cog%" and 
    study not like "%rew%"' |while read ts4d; do
    sp_path=$(find $(dirname $ts4d) -maxdepth 1 -type f -iname '*_spike_percentage.txt' |sed 1q)
    [ -z "$sp_path" -o ! -s "$sp_path" ] && echo "no spike_percentage for $ts4d" >&2 &&  continue
    sp_mean=$(datamash -R3 mean 1 < $sp_path)
    #echo "update rest set sp_path='$sp_path', sp_mean=$sp_mean where ts4d like '$ts4d';"
    echo "$sp_mean,$sp_path,$ts4d"
    # report progress
    let ++cnt
    [ $(( $cnt % 100)) -eq 0 ] && echo "[$(date)] $cnt $ts4d" >&2
done > txt/update_sp.txt
# send updates to sql
#sqlite3 rest.db < txt/update_sp.sql
sqlite3 rest.db < update_sp.sql

