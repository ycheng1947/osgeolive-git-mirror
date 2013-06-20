#!/bin/sh
# Copyright (c) 2009 The Open Source Geospatial Foundation.
# Licensed under the GNU LGPL.
# 
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 2.1 of the License,
# or any later version.  This library is distributed in the hope that
# it will be useful, but WITHOUT ANY WARRANTY, without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details, either
# in the "LICENSE.LGPL.txt" file distributed with this software or at
# web page "http://www.fsf.org/licenses/lgpl.html".

# About:
# =====
# This script will install tomcat 6

# Running:
# =======
# sudo /etc/init.d tomcat6 start

SCRIPT="install_tomcat6.sh"
echo "==============================================================="
echo "$SCRIPT"
echo "==============================================================="

apt-get install --yes tomcat6 tomcat6-admin

#Add the following lines to <tomcat-users> in /etc/tomcat6/tomcat-users.xml
#<role rolename="manager"/>
#<user username="user" password="user" roles="manager"/>

if [ -z "$USER_NAME" ] ; then
   USER_NAME="user"
fi
USER_HOME="/home/$USER_NAME"
BUILD_DIR="$USER_HOME/gisvm"

cp "$BUILD_DIR"/app-conf/tomcat/tomcat-users.xml \
   /etc/tomcat6/tomcat-users.xml

chown tomcat6:tomcat6 /etc/tomcat6/tomcat-users.xml


# something screwed up with the ISO permissions:
chgrp tomcat6 /usr/share/tomcat6/bin/*.sh
adduser "$USER_NAME" tomcat6

echo "==============================================================="
echo "Finished $SCRIPT"
echo Disk Usage1:, $SCRIPT, `df . -B 1M | grep "Filesystem" | sed -e "s/  */,/g"`, date
echo Disk Usage2:, $SCRIPT, `df . -B 1M | grep " /$" | sed -e "s/  */,/g"`, `date`
echo "==============================================================="