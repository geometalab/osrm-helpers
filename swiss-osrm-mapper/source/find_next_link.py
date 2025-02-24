import json
import requests
import os
import sys

def find_next_url(json_file):
    # Extracts the 'next' link from a given JSON file
    with open(json_file, 'r') as f:
        items_result = json.load(f)
    next_url = None
    for link in items_result.get('links', []):
        if link.get('rel') == 'next':
            next_url = link.get('href')
            break
    
    print(f"next_rul: {next_url}")
    return next_url
    
def download_items(next_url, base_dir="files"):
    print("download items...")
    response = requests.get(next_url)
    if response.status_code != 200:
        print(f"ERROR: Failed to retrieve data from {next_url}")
        return

    items_result = json.loads(response.content)

    # Extract download URLs from the assets
    for feature in items_result.get('features', []):
        try:
            for asset_key, asset_value in feature['assets'].items():
                if asset_value['type'].startswith("image/tiff") and 'eo:gsd' in asset_value and asset_value['eo:gsd'] == 0.5:
                    surface_url = asset_value['href']
                    output_file = os.path.join(base_dir, f"{feature['id']}_{asset_key}")
                    download_file(surface_url, output_file)
        except KeyError as e:
            print(f"Error extracting URL from JSON: {e}")

    # Write response JSON to a file for the next iteration
    next_json_file = os.path.join(base_dir, "next_response.json")
    with open(next_json_file, 'w') as f:
        json.dump(items_result, f, indent=4)

    # Check if there's another page to fetch
    next_url = find_next_url(next_json_file)
    if next_url:
        print("Found next URL, continuing to next page...")
        download_items(next_url, base_dir)

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

if __name__ == "__main__":
    # Assume we already have the base JSON file saved locally
    base_json_file = f"files/{sys.argv[1]}"
    base_dir = "files"

    # Extract the next URL from the base JSON file
    next_url = find_next_url(base_json_file)
    if next_url:
        print(f"Next URL found: {next_url}")
        download_items(next_url, base_dir)
    else:
        print("No next URL found.")
