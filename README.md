# Swisstopo OSRM Mapper
## Description
This project generates a shadow or terrain map as a TIFF file for a selected location in Switzerland using elevation data from the swisstopo API. With a single command, users can define a region using a bounding box, fetch the necessary terrain data, and produce an accurate shadow or terrain visualization.

## How it works
### Batch scripts
* ```generate_alti.bat```:
Downloads and merges altitude (elevation) data from GeoTIFF files.
Uses **gdal_calc** and **gdalwarp** to convert data.

* ```generate_shadows.bat```:
Downloads and processes shadow and terrain surface data.
Uses GRASS GIS tools like **r.sun** and **r.horizon** to compute shadows.

* ```importing_alti3D.bat``` and ```importing_surface.bat```:
Those are seperate files, which import altitude data (alti) and surface data into GRASS GIS using r.import.

* ```start_program.bat```:
This script begins the whole process. It sets the settings of the final outcome.
It calls ```generate_alti.bat``` or ```generate_shadows.bat``` based on the user selection.

### Python scripts
* ```download_tiffs.py```:
Reads a JSON file containing geospatial dataset information.
Extracts and downloads TIFF images from URLs.

* ```find_next_link.py```:
Finds the "next" download URL in the dataset API.
Continues downloading more TIFF files if multiple pages exist.

* ```merge_tiffs.py```:
Merges multiple TIFF images into a single file.
Uses **gdal_merge** to process the images.

### wget.exe
```wget.exe``` is a command-line tool for downloading files from the internet. In this case it needs to download and fetch geospatial data as GeoTIFF files from the swisstopo API.

## Requirements
* Python 3.x
* GRASS GIS 8.4
* GDAL

## How to use
You must execute the ```test_rappi.bat``` script in the GRASS GIS Shell. You can modify the bounding box and the filename inside the ```test_rappi.bat``` file. Also set the **output_function** to either "shadow" or "alti" based on what you want to generate. Choose whether to generate shadows alone or include horizon data.

The file will download the tif files out of the swisstopo database on your computer under the ```files``` folder, which will be created once you run the script. Based on the size of your selected location, it could be several gb large. You will find the generated shadows or altitude files as TIFF files inside the ```output``` folder.
