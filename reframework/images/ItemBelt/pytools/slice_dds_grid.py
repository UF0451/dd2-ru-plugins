"""
Author: Wandd3rer
Purpose: Slices a grid DDS file.
"""

# Imports
import os
import sys
from pathlib import Path
from PIL import Image
from utils import parse_user_path, pause_if_interactive, Logger
from config import LOG_FILENAME, TILES_DIRNAME


# Functions
def main():
    # Collects user input
    raw_input = input("Path to DDS image sheet: ")
    input_fpath = parse_user_path(raw_input)

    if not os.path.exists(input_fpath):
        print("[ERROR] File not found.")
        pause_if_interactive()
        sys.exit(1)

    log_fpath = input_fpath.parent / LOG_FILENAME
    name = Path(__file__).name
    logger = Logger(log_fpath, name)
    logger.log("--- DDS Grid Slicer ---")

    try:
        rows = int(input("Number of rows [10]: ") or "10")
        cols = int(input("Number of columns [10]: ") or "10")
        output_size = int(input("Output image size in px (square) [150]: ") or "150")
        while True:
            user_input = input("Force a square DDS grid? (yes/no) [yes]: ") or "yes"
            if user_input.lower() in ["yes", "y"]:
                is_square = True
                break
            elif user_input.lower() in ["no", "n"]:
                is_square = False
                break
            else:
                print("Invalid input. Please enter yes/no.")
        start_id = int(input("Starting item ID [1]: ") or "1")
    except ValueError:
        logger.log("[ERROR] Invalid input value.")
        pause_if_interactive()
        return

    # Makes destination directory
    output_dpath = os.path.join(os.path.dirname(input_fpath), TILES_DIRNAME)
    os.makedirs(output_dpath, exist_ok=True)

    # Loads DDS sheet
    try:
        img = Image.open(input_fpath)
    except Exception as e:
        logger.log(f"[ERROR] Failed to open image: {e}")
        pause_if_interactive()
        return

    # Calculates tile and grid dimensions
    width, height = img.size
    tile_w = width // cols
    tile_h = height // rows

    if is_square:  # Forces a square grid
        tile_size = min(tile_w, tile_h)
        tile_w = tile_size
        tile_h = tile_size
        
    width = tile_w * cols
    height = tile_h * rows

    # Crops the sheet to remove extra padding
    img_cropped = img.crop((0, 0, width, height))

    # Slices image grid into individual tiles
    count = 0
    for r in range(rows):
        for c in range(cols):
            left = c * tile_w
            top = r * tile_h
            right = left + tile_w
            bottom = top + tile_h

            tile = img_cropped.crop((left, top, right, bottom))
            tile = tile.resize((output_size, output_size), Image.Resampling.NEAREST)

            item_id = start_id + count
            out_name = "%d.png" % item_id
            out_fpath = os.path.join(output_dpath, out_name)
            tile.save(out_fpath)
            count += 1

    logger.log(f"Slicing finished. Verify the '{TILES_DIRNAME}' folder for PNG files.")
    logger.log(f"Exported {count} images to {output_dpath}")
    pause_if_interactive()

if __name__ == "__main__":
    main()