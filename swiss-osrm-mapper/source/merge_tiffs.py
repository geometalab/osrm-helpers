import subprocess
import os
import glob
import shutil
import sys

# Define the base directory for files
base_dir = "the8"
merged_tif = os.path.join(base_dir, sys.argv[1])

# Get a list of all .tif files in the base directory
tif_files = glob.glob(os.path.join(base_dir, "*.tif"))

# Check if there are multiple files to merge
if len(tif_files) > 1:
    print("Merging downloaded TIFF files into one...")

    # Create a temporary text file that contains the list of all TIFF files
    tif_list_file = os.path.join(base_dir, "tif_file_list.txt")
    with open(tif_list_file, "w") as f:
        for tif in tif_files:
            f.write(tif + "\n")
            print(tif)

    # Run the gdal_merge command to merge the files
    gdal_merge_command = [
        "gdal_merge.bat",
        "-ot", "Float32",
        "-of", "GTiff",
        "-o", merged_tif,
        "--optfile", tif_list_file
    ]

    try:
        subprocess.run(gdal_merge_command, check=True)
        print(f"Merged file saved as {merged_tif}")
    except subprocess.CalledProcessError as e:
        print(f"Error during merging process: {e}")

elif len(tif_files) == 1:
    # If only one TIFF file, copy it to create surface_all.tif
    print("Only one TIFF file downloaded. Copying it to mergedfile.tif.")
    try:
        shutil.copy(tif_files[0], merged_tif)
        print(f"Copied {tif_files[0]} to {merged_tif}")
    except IOError as e:
        print(f"Error copying file: {e}")

else:
    print("No TIFF files found in the directory.")

print("Merging process completed.")
