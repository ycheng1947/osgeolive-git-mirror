#!/bin/sh
#
# Install the MapTiler application
#
# Created by Klokan Petr Pridal <petr.pridal@klokantech.com>
#
# Copyright (c) 2010-13 The Open Source Geospatial Foundation.
# Licensed under the GNU LGPL version >= 2.1.
#

./diskspace_probe.sh "`basename $0`" begin
BUILD_DIR=`pwd`
####


# live disc's username is "user"
if [ -z "$USER_NAME" ] ; then
   USER_NAME="user"
fi
USER_HOME="/home/$USER_NAME"

TMP="/tmp/build_maptiler"
MAPTILERDEB="maptiler_1.0.beta2_all.deb"
DATA_FOLDER="/usr/local/share/maptiler"
TESTDATA_URL="http://download.osgeo.org/gdal/data/gtiff/utm.tif"


#Can't cd to a directory before you make it, may be uneeded now
mkdir -p "$TMP"

#CAUTION: UbuntuGIS should be enabled only through setup.sh
# Add UbuntuGIS repository (same as QGIS)
#cp ../sources.list.d/ubuntugis.list /etc/apt/sources.list.d/

#Add signed key for repositorys LTS and non-LTS  (not needed?)
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68436DDF  
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160  
apt-get -q update


# Install dependencies
PACKAGES="python python-wxgtk2.8 python-gdal"

echo "Installing: $PACKAGES"
apt-get --assume-yes install $PACKAGES
if [ $? -ne 0 ] ; then
   echo "ERROR: package install failed"
   exit 1
fi


# If MapTiler is not installed then download the .deb package and install it
if [ `dpkg -l maptiler | grep -c '^ii'` -eq 0 ] ; then
  wget -c --progress=dot:mega "http://maptiler.googlecode.com/files/$MAPTILERDEB" \
     --output-document="$TMP/$MAPTILERDEB"
  dpkg -i "$TMP/$MAPTILERDEB"
  #rm "$MAPTILERDEB"
fi

# Test if installation was correct and create the Desktop icon
if [ -e /usr/share/applications/maptiler.desktop ] ; then
  cp /usr/share/applications/maptiler.desktop "$USER_HOME"/Desktop/
  chown "$USER_NAME"."$USER_NAME" "$USER_HOME"/Desktop/maptiler.desktop
  sed -i -e 's/Graphics;/Geography;/' /usr/share/applications/maptiler.desktop
else
  echo "ERROR: Installation of the MapTiler failed."
  exit 1
fi

# Create the directory for data
if [ ! -d "$DATA_FOLDER" ] ; then
   mkdir "$DATA_FOLDER"
fi

# Download the data for testing 
cd "$DATA_FOLDER"
wget -N --progress=dot:mega "$TESTDATA_URL"

# make it available to all projects:
mkdir -p /usr/local/share/data/raster
ln -s "$DATA_FOLDER/utm.tif" /usr/local/share/data/raster/utm11N.tif


# Everything is OK
if [ -n "$VERBOSE" ] ; then
   echo "MapTiler is installed"
   echo "---------------------"
   echo "To try it you should:"
   echo ""
   echo " 1. Start MapTiler by clicking the icon on the Desktop"
   echo " 2. Load in the second step an raster geodata (with georerence/srs), you can try /home/user/data/maptiler/utm.tif"
   echo " 3. Go trough all the steps with 'Next' up to the Render"
   echo " 4. Once the render is finished you can click in the GUI to open a folder with tiles. When you open googlemaps.html or openlayers.html then you see your geodata warped to the overlay of popular interactive web maps as Google Maps."
   echo ""
   echo "The map tiles are displayed directly from your disk. To publish the map to Internet just upload the folder with tiles to any webserver or Amazon S3" 
fi


####
"$BUILD_DIR"/diskspace_probe.sh "`basename $0`" end
