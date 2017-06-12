#!/bin/bash

find /opt/apps/*/logs/ -maxdepth 1 -name "jetty*log" -mtime +0 -type f | xargs gzip  
find /opt/apps/*/logs/ -maxdepth 1 -name "jetty*log*gz" -mtime +8 -type f | xargs rm
