"""
Author: Wandd3rer
Purpose: Extracts TEX files from PAK files. It requires REtool.exe by FluffyQuack.
"""

# Imports
import shutil
import sys
import tempfile
from pathlib import Path
from utils import parse_user_path, pause_if_interactive, Logger, run_retool
from config import (
    LOG_FILENAME, MOD_NAME, MOD_RELPATH, WORK_DIRNAME, TEXLIST_FILENAME,
    RETOOL_FILENAME
)

# Functions
def main():
    # Gets path to game directory
    raw_input = input("Enter full path to your game installation directory: ")
    game_dpath = parse_user_path(raw_input)

    # Makes sure game directory exists
    if not game_dpath.exists():
        print("[ERROR] Game directory not found.")
        pause_if_interactive()
        sys.exit(1)

    # Gets path to REtool directory
    raw_input = input("Enter full path to REtool directory: ")
    retool_dpath = parse_user_path(raw_input)

    # Makes sure REtool directory exists
    if not retool_dpath.exists():
        print("[ERROR] REtool directory not found.")
        pause_if_interactive()
        sys.exit(1)

    # Builds path to REtool executable
    retool_fpath = retool_dpath / RETOOL_FILENAME

    # Sets path to mod directory
    mod_dpath = game_dpath / MOD_RELPATH
    mod_dpath.mkdir(parents=True, exist_ok=True)

    # Creates logger
    log_fpath = mod_dpath / LOG_FILENAME
    name = Path(__file__).name
    logger = Logger(log_fpath, name)
    logger.log("--- TEX Extractor ---")
    logger.log(f"Game directory: {game_dpath}")
    logger.log(f"Output directory: {mod_dpath}")

    # Sets up temp directory
    temp_dpath = Path(tempfile.gettempdir()) / WORK_DIRNAME
    if temp_dpath.exists():
        shutil.rmtree(temp_dpath, ignore_errors=True)
    temp_dpath.mkdir(parents=True)
    logger.log(f"Temporary working dir: {temp_dpath}")

    # Sets path to tex list file
    texlist_fpath = Path(__file__).parent / TEXLIST_FILENAME
    if not texlist_fpath.exists():
        logger.log("[ERROR] TEX list file not found.")
        sys.exit(1)
    logger.log("List file contents:\n" + texlist_fpath.read_text())

    # Gets list of tex filenames
    tex_fnames = []
    with open(texlist_fpath, "r") as f:
        for line in f:
            tex_fnames.append(line.strip().split("/")[-1])

    # Finds PAK files
    all_paks = sorted(game_dpath.glob("*.pak"))
    patch_paks = [p for p in all_paks if "patch" in p.name.lower()]
    ordered_paks = patch_paks + [p for p in all_paks if p not in patch_paks]

    if not ordered_paks:
        logger.log("[ERROR] PAK files not found in game directory.")
        pause_if_interactive()
        sys.exit(1) 

    # TEX extraction
    needed = set(tex_fnames)
    found = set()

    for pak_fpath in ordered_paks:
        logger.log(f"Running REtool on {pak_fpath.name}...")

        try:
            logger.log(f'Using REtool.exe at: {retool_fpath}')
            _, result = run_retool(retool_fpath, texlist_fpath, temp_dpath, pak_fpath)
            logger.log(f"REtool output for {pak_fpath.name}: {result.stdout}\n")
        except Exception as e:
            logger.log(f"[ERROR] Error detected while running REtool on {pak_fpath.name}: {e}")
            continue

        # Looks for extracted target files
        for tex_fname in list(needed):
            for fpath in temp_dpath.rglob(tex_fname):
                if fpath.name == tex_fname:
                    target = mod_dpath / fpath.name
                    try:
                        if target.exists():
                            target.unlink()
                        shutil.move(str(fpath), target)
                        found.add(tex_fname)
                        needed.discard(tex_fname)
                        logger.log(f"Moved {tex_fname} --> {target.relative_to(game_dpath)}")
                    except Exception as e:
                        logger.log(f"Could not move {fpath}: {e}")

        if not needed:
            logger.log("All target .tex files found — stopping early.")
            break
        else:
            logger.log(f"Still missing {sorted(needed)}")

    # Prints out summary
    logger.log("--- Extraction Summary ---")
    logger.log(f"Found:   {sorted(found)}")
    logger.log(f"Missing: {sorted(needed)}")
    if needed:
        logger.log(f"[WARN] Missing TEX files.")

    # Cleans up
    try:
        shutil.rmtree(temp_dpath, ignore_errors=True)
        logger.log("Temporary folder cleaned up.")
    except Exception as e:
        logger.log(f" Could not remove temp folder: {e}")

    logger.log(f"Extraction finished. Verify the '{MOD_NAME}' folder for TEX files.")
    pause_if_interactive()

if __name__ == "__main__":
    main()
