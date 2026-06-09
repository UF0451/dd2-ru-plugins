"""
Author: Wandd3rer
Purpose: Assorted utilities.
"""

# Imports
import subprocess
import sys
import tkinter as tk
from datetime import datetime
from pathlib import Path
from tkinter import filedialog
from typing import Tuple


# Classes
class Logger:
    def __init__(self, filepath: Path, caller_fname: str, clear: bool = False):
        self.filepath = filepath
        self.caller_fname = caller_fname

        if clear and filepath.is_file():
            filepath.unlink()
            print(f"[INFO] Cleared previous log: {filepath}")

        # Only writes header if log file is new or empty
        if not filepath.exists() or filepath.stat().st_size == 0:
            self.log(f"--- Log started at {datetime.now():%Y-%m-%d %H:%M:%S} ---")

    def log(self, message: str, show: bool = True):
        """
        Writes a message to the log file and optionally to console.
        """
        timestamp = datetime.now().strftime("%H:%M:%S")
        line = f"[{timestamp}] {message}"
        with open(self.filepath, "a", encoding="utf-8") as f:
            f.write(f"[{self.caller_fname}] {message}\n")
        if show:
            print(line)

    def separator(self, char: str = "-"):
        """
        Adds a visual separator line to the log file.
        """
        self.log(char * 80, show=False)


# Functions
def parse_user_path(user_input: str, resolve: bool = True) -> Path:
    """
    Parses a user-entered path string into a clean, resolved Path object.
    """
    text = user_input.strip()

    # Removes surrounding angle brackets first
    if text.startswith("<") and text.endswith(">"):
        text = text[1:-1].strip()

    # Removes matching single or double quotes
    if (text.startswith('"') and text.endswith('"')) or (
        text.startswith("'") and text.endswith("'")
    ):
        text = text[1:-1].strip()

    # Expands user home (~)
    path = Path(text).expanduser()

    # Optionally resolves to absolute path
    return path.resolve() if resolve else path


def pause_if_interactive():
    """
    Provides a pause if the script is being run interactively.
    """
    if sys.stdin.isatty():
        input("Press Enter to continue...")


def run_retool(
    retool_fpath: Path,
    tex_fpath: Path,
    cwd: Path,
    pak_fpath: Path | None = None
) -> Tuple[bool, subprocess.CompletedProcess]:
    """
    Runs REtool.exe on a given PAK/TEX file.

    Parameters:
    - retool_fpath: Path to REtool.exe
    - tex_fpath: Path to TEX file or path to list of TEX files. For TEX-->DDS
        conversion the former must be provided.
    - cwd: Path to current working directory.
    - pak_fpath: Path to PAK file. Must be provided along with path to list of
        TEX files to be extracted.

    Returns:
    - Success flag and CompletedProcess object.
    """

    # Command for extracting TEX files
    if pak_fpath:
        cmd = [
            retool_fpath,
            "-h", str(tex_fpath),
            "-x",
            "-skipUnknowns",
            str(pak_fpath),
        ]
    # Command for converting TEX to DDS
    else:
        cmd = [
            retool_fpath,
            str(tex_fpath), 
        ]

    # Runs REtool
    proc = subprocess.run(
        cmd,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    # Error detection
    output = proc.stdout or ""
    if "Error" in output or "ERROR" in output:
        return False, proc
    return True, proc


"""
Asks user for directory containing a given file.
Returns path to file.
"""
def ask_file_dir(fname, title_msg, body_msg) -> Path:
    root = tk.Tk()
    root.withdraw()

    selected: Path | None = None

    dialog = tk.Toplevel(root)
    dialog.title(title_msg)
    dialog.resizable(False, False)
    dialog.geometry("480x180")
    dialog.grab_set()

    # UI
    title = tk.Label(
        dialog,
        text=body_msg,
        font=("Segoe UI", 14, "bold")
    )
    title.pack(pady=(20, 5))

    text = tk.Label(
        dialog,
        text=f"Please select the folder that contains {fname}",
        font=("Segoe UI", 10),
        wraplength=440
    )
    text.pack(pady=(0, 20))

    error = tk.Label(dialog, text="", fg="red")
    error.pack(pady=(0, 5))

    # Logic
    def browse() -> None:
        nonlocal selected

        folder = filedialog.askdirectory(
            parent=dialog,
            title="Select folder"
        )
        if not folder:
            return

        candidate = Path(folder) / fname
        if candidate.exists():
            selected = candidate
            dialog.destroy()
        else:
            error.config(text=f"{fname} was not found in the selected folder.")

    button = tk.Button(dialog, text="Browse…", command=browse)
    button.pack()

    dialog.wait_window()
    root.destroy()

    if selected is None:
        raise RuntimeError("Directory not selected")

    return selected
