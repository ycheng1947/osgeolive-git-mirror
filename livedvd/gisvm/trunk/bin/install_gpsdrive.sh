#!/bin/sh
# Copyright (c) 2009 by Hamish Bowman, and the Open Source Geospatial Foundation
# Licensed under the GNU LGPL v.2.1.
# 
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 2.1 of the License,
# or any later version.  This library is distributed in the hope that
# it will be useful, but WITHOUT ANY WARRANTY, without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Lesser General Public License for more details, either
# in the "LGPL-2.1.txt" file distributed with this software or at
# web page "http://www.fsf.org/licenses/lgpl.html".
#
#
# script to install GpsDrive
#    written by H.Bowman <hamish_b  yahoo com>
#    GpsDrive homepage: http://www.gpsdrive.de
#


# live disc's username is "user"
USER_NAME="user"
USER_HOME="/home/$USER_NAME"

TMP_DIR=/tmp/build_gpsdrive


#### install program ####

## packaged version (2.10pre4) is long out of date, so we build 2.10pre7 manually.
BUILD_LATEST=1

if [ "$BUILD_LATEST" -eq 0 ] ; then
   # install very old pre-packaged version
   PACKAGES="gpsd gpsd-clients python-gps gpsdrive"
else
   # important pre-req
   PACKAGES="gpsd gpsd-clients python-gps"
fi

apt-get install $PACKAGES


#######################
## build latest release
if [ $BUILD_LATEST -eq 1 ] ; then
  VERSION="2.10pre7"

  mkdir "$TMP_DIR"
  cd "$TMP_DIR"

  wget -nv "http://www.gpsdrive.de/packages/gpsdrive-$VERSION.tar.gz"

  tar xzf gpsdrive-$VERSION.tar.gz
  if [ $? -eq 0 ] ; then
    \rm gpsdrive-$VERSION.tar.gz
  fi

  cd gpsdrive-$VERSION


  ## --- apply any patches here ---

  # fix package dependencies
  PATCHES="gpsdrive_fix_deps  gpsdrive_osm_fixes"

  for PATCH in $PATCHES ; do
    wget -nv "https://svn.osgeo.org/osgeo/livedvd/gisvm/trunk/app-data/gpsdrive/$PATCH.patch"
    patch -p0 < "$PATCH.patch"
  done


  cat << EOF > "gpsdrive_fix_icon.patch"
--- data/gpsdrive.desktop.ORIG  2009-08-31 01:42:39.000000000 +1200
+++ data/gpsdrive.desktop       2009-08-31 01:43:19.000000000 +1200
@@ -3,7 +3,7 @@
 Comment=GPS Navigation
 Comment[de]=GPS Navigationsprogramm
 Exec=gpsdrive
-Icon=gpsicon
+Icon=/usr/share/gpsdrive/pixmaps/gpsicon.png
 Terminal=false
 Type=Application
 Categories=Graphics;Network;Geography;
EOF
   patch -p0 < "gpsdrive_fix_icon.patch"


  if [ $? -ne 0 ] ; then
     echo "An error occurred patching package. Aborting install."
     exit 1
  fi


  # install any missing build-dep packages
  NEEDED_BUILD_PKG=`dpkg-checkbuilddeps 2>&1 | cut -f3 -d: | \
    sed -e 's/([^)]*)//g' -e 's/| [^ ]*//'`

  if [ -n "$NEEDED_BUILD_PKG" ] ; then
     apt-get install $NEEDED_BUILD_PKG
  fi

  # build package
  # - debuild and co. should already be installed by setup.sh
  debuild binary
  if [ $? -ne 0 ] ; then
     echo "An error occurred building package. Aborting install."
     exit 1
  fi


  #### install our new custom built packages ####
  cd "$TMP_DIR"
 
  # not needed, we're a client not a central server
  \rm gpsdrive-friendsd_2.10svn2414_amd64.deb

  # get+install at least one OSM icon set package
  #   see http://www.gpsdrive.de/development/map-icons/overview.en.shtml
  wget -nv "http://www.gpsdrive.de/debian/pool/squeeze/openstreetmap-map-icons-square.small_16908_all.deb"
  wget -nv "http://www.gpsdrive.de/debian/pool/squeeze/openstreetmap-map-icons-square.big_16908_all.deb"
  wget -nv "http://www.gpsdrive.de/debian/pool/squeeze/openstreetmap-map-icons-classic.small_16908_all.deb"
  wget -nv "http://www.gpsdrive.de/debian/pool/squeeze/openstreetmap-map-icons_16908_all.deb"

  # holy cow, mapnik-world-boundaries.deb is 300mb!
  #wget -nv "http://www.gpsdrive.de/debian/pool/squeeze/openstreetmap-mapnik-world-boundaries_16662_all.deb"


  CUSTOM_PKGS="gpsdrive*.deb openstreetmap-map*.deb"

  # install package dependencies
  EXTRA_PKGS="osm2pgsql"
  for PKG in $CUSTOM_PKGS ; do
     if [ `echo $PKG | cut -f1 -d_` = "openstreetmap-map-icons" ] ; then
        # skip overenthusiastic recommends
        continue
     fi
     REQ_PKG=`dpkg --info "$PKG" | grep '^ Depends: \|^ Recommends: ' | \
       cut -f2- -d: | tr ',' '\n' | cut -f1 -d'|' | \
       sed -e 's/^ //' -e 's/(.*$//' | tr '\n' ' '`
     EXTRA_PKGS="$EXTRA_PKGS $REQ_PKG"
  done


  EXTRA_PKGS=`echo $EXTRA_PKGS | tr ' ' '\n' | sort -u | \
     grep -v 'gpsdrive\|gpsdrive-data-maps\|openstreetmap-map-icons\|libgeos'`

  TO_INSTALL=""
  for PACKAGE in $EXTRA_PKGS ; do
     if [ `dpkg -l $PACKAGE | grep -c '^ii'` -eq 0 ] ; then
        TO_INSTALL="$TO_INSTALL $PACKAGE"
     fi
  done

  if [ -n "$TO_INSTALL" ] ; then
     apt-get --assume-yes install $TO_INSTALL

     if [ $? -ne 0 ] ; then
        echo "ERROR: package install failed: $TO_INSTALL"
        #exit 1
     fi
  fi


  dpkg -i gpsdrive_*.deb \
          gpsdrive-utils_*.deb \
          openstreetmap-map*.deb


  # cleanup
  if [ -n "$NEEDED_BUILD_PKG" ] ; then
     apt-get remove $NEEDED_BUILD_PKG
  fi

fi
##
## end self-build
#######################




#### install data ####
mkdir "$USER_HOME/.gpsdrive"


if [ 1 -eq 0 ] ; then
  ## needed for newer builds if icons were *not* installed via .debs above
  # minimal icon set
  wget -nv "http://downloads.sourceforge.net/project/gpsdrive/additional%20data/minimal%20icon%20set/openstreetmap-map-icons-minimal.tar.gz?use_mirror=internode"
  cd /
  tar xzf "$TMP_DIR"/openstreetmap-map-icons-minimal.tar.gz
  cd "$TMP_DIR"

  #debug dummy copy of geoinfo.db
  #tar xzf openstreetmap-map-icons-minimal.tar.gz usr/share/icons/map-icons/geoinfo.db
  #cp usr/share/icons/map-icons/geoinfo.db "$USER_HOME/.gpsdrive/"
  #  .gpsdrive/gpsdriverc: geoinfofile = $USER_HOME/.gpsdrive/geoinfo.db
fi



cat << EOF > "$USER_HOME/.gpsdrive/gpsdriverc"
lastlong = 151.2001
lastlat = -33.8753
scalewanted = 50000
dashboard_3 = 12
autobestmap = 0
EOF


# Sydney maps
wget -nv "https://svn.osgeo.org/osgeo/livedvd/gisvm/trunk/app-data/gpsdrive/gpsdrive_syd_tileset.tar.gz"

cd "$USER_HOME/.gpsdrive/"
tar xzf "$TMP_DIR"/gpsdrive_syd_tileset.tar.gz

echo "Convention_Centre   -33.8750   151.2005   WLAN" > "$USER_HOME/.gpsdrive/way.txt"


# bypass Mapnik wanting 300mb World Boundaries DB to be installed
sed -e 4594,4863d "$TMP_DIR/gpsdrive-$VERSION/build/scripts/mapnik/osm-template.xml" > "$USER_HOME/.gpsdrive/osm.xml"


if [ $? -eq 0 ] ; then
   rm -rf "$TMP_DIR"
fi


chown -R $USER_NAME:$USER_NAME "$USER_HOME/.gpsdrive"

cp /usr/share/applications/gpsdrive.desktop "$USER_HOME/Desktop/"
chown $USER_NAME:$USER_NAME "$USER_HOME/Desktop/gpsdrive.desktop"



#### install OSM data for Mapnik Support ####
#
# - Download OSM planet file from
#  http://www.osmaustralia.org/osmausextract.php
#    or
#  http://downloads.cloudmade.com/oceania/australia
#
# - Set up PostGIS Database and import data
#  see https://sourceforge.net/apps/mediawiki/gpsdrive/index.php?title=Setting_up_Mapnik
#

echo "Finished installing GpsDrive."


cat << EOF

== Testing ==

=== If no GPS is plugged in ===
* Double click on the GpsDrive desktop icon
* You should see a map of downtown Sydney, after about 10 seconds
a waypoint marker for the Convention Centre should appear.
* Set the map scale to 1:10,000 either by dragging the slider at the
bottom or by using the +,- buttons (not magnifying glass)
* Enter Explore Mode by pressing the "e" key or in the Map Control button.
* Use the arrow keys or left mouse button to move off screen.
* Right click to set destination and leave Explore Mode

==== Downloading maps ====
* Change the scale setting to 1:1,000,000 you should see a continental map 
* Enter Explore Mode again ("e") and left click on the great barrier reef
* Options -> Map -> Download
** Map source: NASA LANDSAT, Scale: 1:500,000, [Download Map]
** When download is complete click [ok] then change the preferred scale
slider to 1:500,000
** This will be of more use in remote areas.
* Explore to the coast, click on an airport, headland, or some other
conspicuous feature. You might want to use the magnifying glass buttons
to zoom in on it better. Use a right click set the target on some other
conspicuous feature nearby then demagnify back out.
* Options -> Map -> Download
** Map source: OpenStreetMap, Scale: 1:150,000, left-click on map to center
the green preview over your target and what looks like a populated area.
** [Download Map]
** When download is complete click [ok] then change the preferred scale
slider to 1:150,000 and you should see a (rather rural) road map. This will
be more interesting in built up areas.

==== Overlay a GPX track ====
* In the ~/.gpsdrive/tracks/ directory you will find australia.gpx
which is a track line following the coastline.
* Options -> Import -> GPX track
* Hidden folders are hidden in the file picker, but just start typing
~/.gpsdrive and hit enter. You should then see the tracks/ directory
and be able to load australia.gpx.
* A red trace should appear along the coastline.
* Check that it lines up well with the coast as shown in map tiles of
varying scale.

=== If a GPS is plugged in ===
* Make sure gpsd is running by starting "xgps" from the command line.
* The program will automatically detect gpsd and jump to your current
position. This should bring up a continental map as you won't have any
map tiles downloaded for your area yet.
* See the above "Downloading Maps" section to get some local tiles.
* If you have a local GPX track of some roads try loading that and making
sure everything lines up, as detailed in the above "Overlay a GPX track"
section.

That's it.

EOF
