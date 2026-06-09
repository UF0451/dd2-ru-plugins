"""
Author: Wandd3rer
Purpose: Converts a TEX file to DDS format. It requires REtool.exe by FluffyQuack.
"""

# Imports
import sys
import tempfile
from pathlib import Path
from utils import parse_user_path, pause_if_interactive, Logger, run_retool
from config import LOG_FILENAME, MOD_NAME, MOD_RELPATH, RETOOL_FILENAME



# Functions
def tex_stems(tex_fnames):
    """
    Returns stems to match resulting .dds files.
    Example: 'tex_ui01c00_00_iam.tex.760230703' --> 'tex_ui01c00_00_iam'
    Takes substring before '.tex' as stem.
    """
    stems = []
    for t in tex_fnames:
        if ".tex" in t:
            stems.append(t.split(".tex", 1)[0])
        else:
            stems.append(Path(t).stem)
    return set(stems)

def main():
    # Builds path to mod directory
    raw_input = input("Enter full path to your game installation directory: ")
    game_dpath = parse_user_path(raw_input)
    mod_dpath = game_dpath / MOD_RELPATH

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

    # Creates logger
    log_fpath = mod_dpath / LOG_FILENAME
    name = Path(__file__).name
    logger = Logger(log_fpath, name)
    logger.log("--- TEX --> DDS Converter ---")

    # Makes sure mod directory exists
    if not mod_dpath.exists():
        logger.log(f"[ERROR] Mod directory not found: {mod_dpath}")
        pause_if_interactive()
        sys.exit(1)

    # Makes sure there are tex files
    tex_fnames = list(mod_dpath.glob("*.tex.*"))
    if not tex_fnames:
        logger.log(f"[ERROR] No *.tex.* files found in {mod_dpath} to convert.")
        pause_if_interactive()
        sys.exit(1)

    tex_fpaths = [file.resolve() for file in mod_dpath.glob('*.tex.*') if file.is_file()]
    logger.log(f"Found {len(tex_fnames)} TEX files in: {mod_dpath}")

    # Converts TEX to DDS
    with tempfile.TemporaryDirectory() as tmpdir:
        temp_dpath = Path(tmpdir)
        for tex_fpath in tex_fpaths:

            # Runs REtool, output files go into mod directory
            logger.log(f"Running REtool on {tex_fpath.name}...")
            try:
                _, result = run_retool(retool_fpath, tex_fpath, temp_dpath)
                logger.log(f"REtool output for {tex_fpath.name}: {result.stdout}\n")
            except Exception as e:
                logger.log(f"[ERROR] Error detected while running REtool on {tex_fpath.name}: {e}")

    logger.log(f"Conversion finished. Verify the '{MOD_NAME}' folder for DDS files.")
    pause_if_interactive()

if __name__ == "__main__":
    main()
