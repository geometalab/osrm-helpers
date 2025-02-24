import requests
import json
import os
import sys

# Define the base directory for files
base_dir = "files"

# JSON input file for swissSURFACE3D
json_file = os.path.join(base_dir, sys.argv[1])

# Function to download a file from a URL
def download_file(url, output_file):
    print(f"Downloading from {url}...")
    response = requests.get(url, stream=True)
    if response.status_code == 200:
        with open(output_file, 'wb') as out_file:
            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    out_file.write(chunk)
        print(f"Saved {output_file}")
    else:
        print(f"Failed to download {output_file}. Status code: {response.status_code}")

# Create the base directory if it doesn't exist
if not os.path.exists(base_dir):
    os.makedirs(base_dir)

# Open the JSON file and extract GeoTIFF URLs to download
with open(json_file, 'r') as f:
    json_data = json.load(f)

    # Loop through each feature in the JSON
    for feature in json_data.get('features', []):
        try:
            # Access the GeoTIFF file under the 'assets' key
            for asset_key, asset_value in feature['assets'].items():
                if asset_value['type'].startswith("image/tiff") and 'eo:gsd' in asset_value and asset_value['eo:gsd'] == 0.5:
                    json_url = asset_value['href']
                    # Create an output filename based on the feature ID and asset key
                    output_file = os.path.join(base_dir, f"{feature['id']}_{asset_key}")
                    # Download the file
                    download_file(json_url, output_file)
        except KeyError as e:
            print(f"Error extracting URL from JSON: {e}")

print("Downloading process completed.")
