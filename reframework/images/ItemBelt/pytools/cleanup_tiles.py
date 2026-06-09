"""
Author: Wandd3rer
Purpose: Removes sliced tiles not listed in the keep-list file.
"""

import sys
from pathlib import Path
from utils import parse_user_path, pause_if_interactive, Logger
from config import (
    LOG_FILENAME, MOD_RELPATH, TILES_DIRNAME, KEEPLIST_FILENAME
)

def main():
    # Builds path to mod directory
    raw_input = input("Enter full path to your game installation directory: ")
    game_dpath = parse_user_path(raw_input)
    mod_dpath = game_dpath / MOD_RELPATH

    # Creates logger
    log_fpath = mod_dpath / LOG_FILENAME
    name = Path(__file__).name
    logger = Logger(log_fpath, name)
    logger.log("--- Tile Files Cleaner ---")

    # Sets relevant paths
    tiles_dpath = game_dpath / MOD_RELPATH / TILES_DIRNAME
    keep_fpath = Path(__file__).parent / KEEPLIST_FILENAME

    if not tiles_dpath.exists():
        logger.log("[WARN] No tiles directory found, skipping cleanup")
        pause_if_interactive()
        sys.exit(1)

    if not keep_fpath.exists():
        logger.log("[WARN] No keep file found, skipping cleanup.")
        pause_if_interactive()
        sys.exit(1)

    # Reads IDs to keep
    with open(keep_fpath) as f:
        keep_tiles = {int(line.strip()) for line in f if line.strip().isdigit()}

    n_removed = 0
    n_tiles = sum(1 for entry in tiles_dpath.iterdir() if entry.is_file())
    for tile_fpath in tiles_dpath.glob("*.png"):
        try:
            num = int(tile_fpath.stem)
        except ValueError:
            continue
        if num not in keep_tiles:
            tile_fpath.unlink()
            n_removed += 1

    # Checks missing tiles
    n_missing = len(keep_tiles) - (n_tiles - n_removed)
    if n_missing != 0:
        logger.log(f"[WARN] Missing {n_missing} tiles.")

    logger.log(f"Removed {n_removed} unused tiles.")
    logger.log(f"Kept {n_tiles - n_removed} out of the {len(keep_tiles)} tiles defined in {keep_fpath}")
    pause_if_interactive()

if __name__ == "__main__":
    main()