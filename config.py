import os
import json
import psutil
from pathlib import Path

# If running as a python script, cwd_1 is what we need
cwd_1 = os.path.dirname(os.path.realpath(__file__))

# If running as a pyinstaller executable, cwd_2 is what we need
cwd_2 = os.getcwd()

# Prefer whichever one has a pre-existing config.json, if any
# Alternatively, prefer whichever one is NOT AppData :)
if "AppData" in cwd_1:
    cwd = cwd_2
else:
    cwd = cwd_1

cfg_p = os.path.join(cwd, "config.json")

print("Config located at:", cfg_p)

def validate_cfg():
    global cfg

    for k,v in cfg.items():
        if v == "":
            return False

        if not os.path.isdir(v) and not os.path.isfile(v):
            return False

    if "REFLEX_DIR" not in cfg:
        return False

    if "REPLAY_DIR" not in cfg:
        return False

    if "REFLEX_EXE_PATH" not in cfg:
        return False

    if "REPLAY_DATA_PATH" not in cfg:
        return False

    return True

def get_reflex_exe_p():
    reflex_proc = [proc for proc in psutil.process_iter() if proc.name() == "reflex.exe"][0]
    return reflex_proc.exe()

def setup_cfg():
    global cfg

    cfg = {}

    while True:
        try:
            cfg["REFLEX_EXE_PATH"] = get_reflex_exe_p()
            break
        except:
            input("Please start Reflex Arena and press Enter, or manually fill out your config and restart this script.")

    reflex_dir = os.path.dirname(cfg["REFLEX_EXE_PATH"])

    cfg["REFLEX_DIR"] = reflex_dir
    cfg["REPLAY_DIR"] = os.path.join(reflex_dir, "replays")
    cfg["REPLAY_DATA_PATH"] = str(next(Path(reflex_dir).rglob("ReplayBrowserData.lua")))

    save_cfg()

def save_cfg():
    with open(cfg_p, "w+") as cfg_f:
        cfg_f.write(json.dumps(cfg))

# Read config, validate, set up new config if not valid
try:
    with open(cfg_p, "r") as cfg_f:
        cfg = json.loads(cfg_f.read())

        if not validate_cfg():
            setup_cfg()
except:
    setup_cfg()
