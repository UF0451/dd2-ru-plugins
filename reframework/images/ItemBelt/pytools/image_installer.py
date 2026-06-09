"""
Author: Wandd3rer
Purpose: Installs item images for the ItemBelt mod.
"""

# Imports
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional, Tuple
from utils import parse_user_path, pause_if_interactive, Logger, ask_file_dir
from config import (
    LOG_FILENAME, MOD_NAME, MOD_RELPATH, TILES_DIRNAME, EXTRACTOR_FILENAME,
    CONVERTER_FILENAME, SLICER_FILENAME, CLEANER_FILENAME, RETOOL_FILENAME,
    DD2_FILENAME
)

# Functions
def run_step(script_fpath, input, logger) -> int:
    """
    Runs any .py script that requires input and a Logger.
    """
    logger.log(f"Running {script_fpath.name} from run_step()")
    try:
        subprocess.run(
            [sys.executable, str(script_fpath)],
            input=str(input),
            text=True,
            check=True
        )
        return 0
    except subprocess.CalledProcessError as e:
        logger.log(f"[ERROR] {script_fpath.name} failed: {e}")
        return 1


def ask_slicer_params(logger) -> Optional[Tuple[int, int, int, bool, int]]:
    """
    Asks inputs for slicer script. 
    """
    try:
        rows = "10"
        cols = "10"
        size = "150"
        betterui = input("Is the 'Better UI - Informative Icons' mod installed? (yes/no) [yes]: ") or "yes"
        start_id = "1"
        return int(rows), int(cols), int(size), betterui.lower().startswith("y"), int(start_id)
    except ValueError as e:
        logger.log(f"[ERROR] Invalid input value: {e}")
        return None


def main():
    # Gets path to game directory
    game_dpath = ask_file_dir(
        DD2_FILENAME,
        "Folder Search",
        "Search for DD2 installation folder"
    ).parent
   
    if not game_dpath.exists():
        print(f"[ERROR] Invalid directory: {game_dpath}")
        pause_if_interactive()
        return

    # Sets path to mod directory
    mod_dpath = game_dpath / MOD_RELPATH
    if not mod_dpath.exists():
        print(f"[ERROR] Invalid directory: {mod_dpath}")
        pause_if_interactive()
        return

    # Sets paths to scripts
    here = Path(__file__).parent
    extractor_fpath = here / EXTRACTOR_FILENAME
    converter_fpath = here / CONVERTER_FILENAME
    slicer_fpath = here / SLICER_FILENAME
    cleaner_fpath = here / CLEANER_FILENAME

    # Checks if REtool.exe is in the PATH
    retool_found = shutil.which(RETOOL_FILENAME)
    if retool_found:
        retool_dpath = Path(retool_found).parent
    else:
        retool_dpath = ask_file_dir(
            RETOOL_FILENAME,
            "Folder Search",
            "Search for REtool folder"
        ).parent

    # Creates logger
    log_fpath = mod_dpath / LOG_FILENAME
    name = Path(__file__).name
    logger = Logger(log_fpath, name, clear=True)
    logger.log(f">>> Dragon's Dogma 2: Image Installer for {MOD_NAME} Mod <<<")

    # Builds the exact same interactive input sequence expected in steps 1 and 2
    answers = (
        f"{game_dpath}\n"
        f"{retool_dpath}\n"
    )

    # Step 1: Extracts TEX files
    errno = run_step(extractor_fpath, answers, logger)
    if errno != 0:
        logger.log("[ERROR] Texture extraction failed. Aborting.")
        pause_if_interactive()
        sys.exit(1)
    
    # Step 2: Converts TEX files to DDS
    errno = run_step(converter_fpath, answers, logger)
    if errno != 0:
        logger.log("[ERROR] DDS conversion failed. Aborting.")
        pause_if_interactive()
        sys.exit(1)

    # Step 3: Gets list of DDS files
    dds_fpaths = sorted(mod_dpath.glob("*.dds"))
    if not dds_fpaths:
        logger.log(f"[ERROR] No DDS files found in {MOD_NAME} directory.")
        pause_if_interactive()
        sys.exit(1)
    logger.log(f"Found {len(dds_fpaths)} DDS files to slice.")

    # Step 4: Sets inputs for slicer
    params = None
    while params is None:
        print("\nConfigure slicer parameters (press Enter to accept defaults):")
        params = ask_slicer_params(logger)
        if params is None:
            logger.log("[ERROR] Slicer got invalid input.")
        else:
            break

    # Step 5: Slices DDS grids
    rows, cols, size, betterui, _ = params
    offset = rows * cols  # How much to increment start_id each time
    start_ids = {fpath.name : int(fpath.name.split("_")[2])*offset + 1 for fpath in dds_fpaths}

    if betterui:
        logger.log("'Better UI - Informative Icons' mod is installed.")
        square = ['no', 'no', 'no', 'no']
    else:
        logger.log("'Better UI - Informative Icons' mod is not installed.")
        square = ['yes', 'yes', 'yes', 'no']

    for i, fpath in enumerate(dds_fpaths):
        current_id = start_ids[fpath.name]
        logger.log(f"Slicing {fpath.name} (start_id={current_id})")

        # Builds the exact same interactive input sequence the slicer expects
        answers = (
            f"{fpath}\n"
            f"{rows}\n"
            f"{cols}\n"
            f"{size}\n"
            f"{square[i]}\n"
            f"{current_id}\n"
        )

        errno = run_step(slicer_fpath, answers, logger)
        if errno != 0:
            logger.log(f"[ERROR] DDS grid slicing failed for {fpath.name}")
    logger.log("All DDS files processed.")

    # Step 6: Removes unnecessary tiles
    errno = run_step(cleaner_fpath, game_dpath, logger)
    if errno != 0:
        logger.log("[WARN] Problems found while attempting to clean up.")

    logger.log(f"Check tiles in: {mod_dpath / TILES_DIRNAME}")
    logger.log(f"Log saved at: {log_fpath}")
    pause_if_interactive()

if __name__ == "__main__":
    main()