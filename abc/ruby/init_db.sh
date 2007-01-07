#!/bin/sh
#
# by Hiromasa YOSHIMOTO <y@momonga-linux.org>

SQL=`dirname $0`/pkgs.sql
if [ ! -f $SQL ]; then
    echo "no pkgs.sql"
    exit 1
fi

[ -f pkgs.db ] && mv pkgs.db pkgs.db.old

sqlite3  pkgs.db  < $SQL

exit 0