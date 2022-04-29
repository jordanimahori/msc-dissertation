# Run this script from within the preprocessing directory

# In some cases, lack of available imagery will cause only the LAT/LON bands to be exported, resulting in a file size
# of approximately 12MB. This script identifies and then deletes those. Furthermore, due to as-yet-unsolved issues
# relating to varying spatial resolution, a small number of sites at extreme latitudes in SSA are exporting the
# wrong number of tiles due to the bounding box fitting more tiles than it should at 30m per pixel. This also
# identifies and removes those.


# Remove EarthEngine Mixer Files
rm *.json

# Find and remove any files where only LAT/LON exported (i.e. there was no Landsat imagery for the desired period)
find . -size 13M >> no_imagery.txt
find . -size 13M -delete

# Find and remove any files which exported the wrong number of tiles (ASSUMING THAT NRINGS = 2)
find . -size +56M >> faulty_imagery.txt
find . -size -55M >> faulty_imagery.txt

find . -size +56M -delete
find . -size -56M -delete