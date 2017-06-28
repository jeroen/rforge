#!/bin/sh
cd /home/jeroen/rforge/
/usr/bin/Rscript sync.R > cron.log 2>&1
exit 0
