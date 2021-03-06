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
# This script will install apache2


./diskspace_probe.sh "`basename $0`" begin
####


apt-get install --yes apache2

if [ -z "$USER_NAME" ] ; then
   USER_NAME="user"
fi

# add "user" to the www-data group
adduser "$USER_NAME" www-data


mkdir -p /var/www/html
wget -nv http://www.osgeo.org/favicon.ico -O /var/www/html/favicon.ico


####
./diskspace_probe.sh "`basename $0`" end
