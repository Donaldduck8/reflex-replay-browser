import os
import re
import sys
import time
import json
import ctypes
import psutil
import traceback
import subprocess

from config import cfg
from datetime import datetime
from slpp import slpp as lua
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

# Dirty hack to avoid failing to parse replays with broken UTF-8 player names
import codecs
codecs.register_error("strict", codecs.ignore_errors)

from unidecode import unidecode

SKIPPED_REPLAYS = []
BROKEN_REPLAYS = []

INT32_MAX = 2147483647

# BOILERPLATE GARBAGE

def sanitize(filename):
    """Return a fairly safe version of the filename.

    We don't limit ourselves to ascii, because we want to keep municipality
    names, etc, but we do want to get rid of anything potentially harmful,
    and make sure we do not exceed Windows filename length limits.
    Hence a less safe blacklist, rather than a whitelist.
    """
    blacklist = ["\\", "/", ":", "*", "?", "\"", "<", ">", "|", "\0"]
    reserved = [
        "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5",
        "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5",
        "LPT6", "LPT7", "LPT8", "LPT9",
    ]  # Reserved words on Windows
    filename = "".join(c for c in filename if c not in blacklist)
    # Remove all charcters below code point 32
    filename = "".join(c for c in filename if 31 < ord(c))
    # filename = unicodedata.normalize("NFKD", filename) # TODO: Removing this since it breaks CJK lettering
    filename = filename.rstrip(". ")  # Windows does not allow these at end
    filename = filename.strip()

    if all([x == "." for x in filename]):
        filename = "__" + filename

    if filename in reserved:
        filename = "__" + filename

    if len(filename) == 0:
        filename = "__"

    if len(filename) > 255:
        parts = re.split(r"/|\\", filename)[-1].split(".")
        if len(parts) > 1:
            ext = "." + parts.pop()
            filename = filename[:-len(ext)]
        else:
            ext = ""
        if filename == "":
            filename = "__"
        if len(ext) > 254:
            ext = ext[254:]
        maxl = 255 - len(ext)
        filename = filename[:maxl]
        filename = filename + ext
        # Re-check last character (if there was no extension)
        filename = filename.rstrip(". ")
        if len(filename) == 0:
            filename = "__"

    filename = filename.replace("\\", "")

    return filename

# ACTUAL CODE

def process_exists(process_name):
    """
    Returns whether or not a given process name is being used by an existing process
    :param process_name: The full name of the process, e.g. "reflex.exe"
    :return: True or False
    """
    return len([proc for proc in psutil.process_iter() if proc.name() == process_name]) > 0


def start_reflex():
    # Make sure to set proper CWD when using subprocess.Popen from another directory
    process = subprocess.Popen(cfg["REFLEX_EXE_PATH"], stdout=subprocess.PIPE, creationflags=0x08000000, cwd=cfg["REFLEX_DIR"])


def skip_if_invalid_and_no_renaming(replay_name):
    """
    Determines whether or not a replay should be skipped based on its name. If
    a replay name cannot be properly printed by Reflex, it must be skipped
    :param replay_name: The replay name to be checked
    :return: True or False depending on if the replay is valid or not
    """

    global SKIPPED_REPLAYS

    # If this script will rename the replay, there is nothing to worry about
    if cfg["REPLAY_RENAMING"]:
        return True

    if replay_name in SKIPPED_REPLAYS:
        return False

    if replay_name.isascii() and replay_name.isprintable():
        return True
    else:
        if replay_name not in SKIPPED_REPLAYS:
            print("Found replay with invalid filename: " + replay_name + ", skipping...")
            SKIPPED_REPLAYS.append(replay_name)
        return False


def wrap_lua_ident(ident):
    """
    Returns a wrapped lua identifier that can be used in Lua constructors. Normally,
    non-standard identifiers such as string containing spaces cannot be used in
    constructors
    :param ident: The identifier to be wrapped
    :return: The wrapped identifier string
    """

    return "[\"" + ident + "\"]"


def get_replay_header(replay_d):
    """
    Returns the ReplayHeader object for a given replay
    :param replay_d: The entire replay file as a bytearray
    :return: ReplayHeader object containing various information about the replay
    """

    if len(replay_d) < 1384:
        raise ValueError

    REPLAY_TAG = 0xD00D001D
    SERVER_MAX_PLAYERS = 16

    class ReplayHeaderPlayer(ctypes.Structure):
        _fields_ = (
            ("name", ctypes.c_char*32),
            ("score", ctypes.c_int32),
            ("team", ctypes.c_int32),
            ("steamId", ctypes.c_uint64)
        )

    # 1384 bytes overall
    class ReplayHeader(ctypes.Structure):
        _fields_ = (
            ("tag", ctypes.c_uint32),
            ("protocolVersion", ctypes.c_uint32),
            ("playerCount", ctypes.c_uint32),
            ("markerCount", ctypes.c_uint32),
            ("unknown1", ctypes.c_uint32),
            ("workshopId", ctypes.c_uint64),
            ("epochStartTime", ctypes.c_uint64),
            ("szGameMode", ctypes.c_char*64),
            ("szMapTitle", ctypes.c_char*256),
            ("szHostName", ctypes.c_char*256),
            ("players", ReplayHeaderPlayer*SERVER_MAX_PLAYERS)
        )

    # Construct replay header
    replay_header = ReplayHeader.from_buffer(replay_d[0:1384])

    return replay_header


def get_max_timecode_fuzzy(replay_d, min_tc):
    MAX_DIFF_BETWEEN_TIMECODES = 96
    NUM_MATCHES_REQUIRED = 4
    NUM_SEARCH_VALUES = 500

    start = len(replay_d) - 4

    for x in range(start, start - NUM_SEARCH_VALUES, -1):
        matches = 0
        matches_values = []

        byte_seq_1 = replay_d[x : x + 4]
        value_1 = ctypes.c_uint32.from_buffer(byte_seq_1).value

        # Make sure value is greater than minimum timecode
        if value_1 < min_tc:
            continue

        matches_values.append(value_1)

        # Check for other values earlier in the replay than byte_seq_1
        for y in range(x - 4, x - 4 - NUM_SEARCH_VALUES, -1):
            byte_seq_2 = replay_d[y : y + 4]
            value_2 = ctypes.c_uint32.from_buffer(byte_seq_2).value

            # Make sure value is greater than the minimum timecode, but less than value_1
            if value_2 < min_tc or value_2 > value_1:
                continue

            # Make sure difference between values is small
            if abs(value_1 - value_2) > MAX_DIFF_BETWEEN_TIMECODES:
                continue

            # Make sure value hasn't already been recorded
            if value_2 in matches_values:
                continue

            matches_values.append(value_2)

            matches += 1

            if matches > NUM_MATCHES_REQUIRED:
                return value_1

    print("Could not find confident maximum timecode")
    return INT32_MAX


def get_last_occurance_record(replay_d, min_score_b):
    # Find last occurance of min_score byte sequence in the replay
    search_start = 1384

    while True:
        # Find next occurance of record's 4 byte sequence
        index = replay_d.find(min_score_b, search_start)

        if index == -1:
            print("Could not find any occurance of record", min_score_b.hex())
            return 0

        # Check if there are two other instances of this sequence closeby (say within 60 bytes)
        # Also check that there are no instances of FF FF FF FF nearby
        # This is to weed out false positives (usually found in the embedded map)
        matches = replay_d[index : index + 60].count(min_score_b)
        matches_backup = replay_d[index - 200 : index + 60].count(bytes.fromhex("FFFFFFFF"))
        if matches == 3 and matches_backup == 0:
            return index
        else:
            search_start = index + 1


def get_timecode_from_index_fuzzy(replay_d, min_tc, max_tc, min_score_index, min_score):
    # We are now (very likely) in the vicinity of the run
    # Move back to the first thing that looks like a timestamp

    MAX_DIFF_BETWEEN_TIMECODES = 96
    NUM_MATCHES_REQUIRED = 4
    NUM_SEARCH_VALUES = 500

    start = min_score_index - 4

    for x in range(start, start - NUM_SEARCH_VALUES, -1):
        matches = 0

        byte_seq_1 = replay_d[x : x + 4]
        value_1 = ctypes.c_uint32.from_buffer(byte_seq_1).value

        # Make sure value is within timecode parameters
        if value_1 < min_tc or value_1 > max_tc:
            continue

        # Check for other values earlier in the replay than byte_seq_1
        for y in range(x, x - NUM_SEARCH_VALUES, -1):
            byte_seq_2 = replay_d[y : y + 4]
            value_2 = ctypes.c_uint32.from_buffer(byte_seq_2).value

            # Make sure value is greater than the minimum timecode, but less than value_1
            if value_2 < min_tc or value_2 > value_1:
                continue

            # Make sure difference between values is small
            if abs(value_1 - value_2) > MAX_DIFF_BETWEEN_TIMECODES:
                continue

            matches += 1

            if matches > NUM_MATCHES_REQUIRED:
                # Adjust timestamp by subtracting run duration
                # Give it a 1000ms buffer
                value_1 -= (min_score + 1000)

                return value_1

    print("Could not find confident PB timecode")
    return 0


def get_min_score_and_player_name(replay_header):
    # Get best score
    min_score = INT32_MAX
    player_name = ""

    for x in replay_header.players:
        if x.score != 0 and x.score < min_score:
            min_score = x.score
            player_name = x.name

    if isinstance(player_name, (bytes, bytearray)):
        player_name = player_name.decode("utf-8")

    return min_score, player_name


def get_min_score(replay_header):
    min_score, player_name = get_min_score_and_player_name(replay_header)

    return min_score


def get_timecode(replay_header, replay_d):
    # Get best score
    min_score = get_min_score(replay_header)

    # If no time has been set, there's no timestamp to find
    if min_score == 0 or min_score == INT32_MAX:
        return 0

    min_score_b = min_score.to_bytes(4, byteorder="little", signed=True)

    # Find minimum and maximum timecodes
    min_tc_b = replay_d[1384:1388]
    min_tc = ctypes.c_uint32.from_buffer(min_tc_b).value

    max_tc = get_max_timecode_fuzzy(replay_d, min_tc)

    min_score_index = get_last_occurance_record(replay_d, min_score_b)

    if min_score_index == 0:
        return 0

    return get_timecode_from_index_fuzzy(replay_d, min_tc, max_tc, min_score_index, min_score)


def format_score_as_string(score):
    ms = int(score % 1000)
    score -= ms
    score /= 1000

    s = int(score % 60)
    score -= s
    score /= 60

    m = int(score)

    return f'{m:02}.{s:02}.{ms:03}'


def read_prev_data():
    data_p = cfg["REPLAY_DATA_PATH"]

    with open(data_p, "r") as data_f:
        data_s_current = data_f.read()

        try:
            previous_data = lua.decode(re.search(r"replayBrowserTable = ([\s\S]*?);", data_s_current).group(1))
        except:
            previous_data = {"replays": [], "ids": [], "info": {}}

    return previous_data


def write_new_data(data):
    data_p = cfg["REPLAY_DATA_PATH"]

    # Create LUA
    lines = [
        "function getReplayBrowserTable()" + "\n",
        "\tlocal replayBrowserTable = " + lua.encode(data) + ";" + "\n",
        "\treturn replayBrowserTable;" + "\n",
        "end"
    ]

    # Update ReplayBrowserData.lua
    with open(data_p, "w+") as data_f:
        data_f.writelines(lines)


def get_info_in_prev_data(prev, dirs, replay_name):
    try:
        for dir in dirs:
            prev = prev["folders"][dir]

        return prev["info"][replay_name]
    except:
        return None


def get_replay_info(replay_p):
    info = {}

    # Read replay
    with open(replay_p, "rb") as replay_f:
        replay_d = bytearray(replay_f.read())

    print("Indexing " + replay_p)

    # Get replay header
    replay_header = get_replay_header(replay_d)

    if replay_header.szGameMode == b"RACE":
        info["timecode"] = get_timecode(replay_header, replay_d)
    else:
        info["timecode"] = 0

    info["workshopId"] = replay_header.workshopId
    info["epochStartTime"] = datetime.utcfromtimestamp(replay_header.epochStartTime).strftime('%Y-%m-%d %H:%M:%S UTC')
    info["szMapTitle"] = replay_header.szMapTitle.decode("utf-8")

    return info, replay_header


def navigate(prev, dirs):
    data = {"folders": {}, "replays": [], "ids": [], "info": {}}

    dir = os.path.join(cfg["REPLAY_DIR"], *dirs)

    entries = os.listdir(dir)

    folders = [entry for entry in entries if os.path.isdir(os.path.join(dir, entry))]
    replays = [Path(entry).stem for entry in entries if os.path.isfile(os.path.join(dir, entry)) and entry.endswith(".rep")]
    replays = [entry for entry in replays if skip_if_invalid_and_no_renaming(entry)]

    data["replays"] = replays

    global BROKEN_REPLAYS

    REPLAYS_RENAMED = False

    for replay_name in data["replays"]:
        if replay_name in BROKEN_REPLAYS:
            continue

        try:
            replay_name_wrapped = wrap_lua_ident(replay_name)

            replay_p = os.path.join(dir, replay_name + ".rep")

            # Try to get info from previous data
            info = get_info_in_prev_data(prev, dirs, replay_name)

            # If replay is new, calculate info ourselves
            if info is None:
                info, replay_header = get_replay_info(replay_p)

                # If replay renaming is enabled, do that now
                if cfg["REPLAY_RENAMING"] and replay_header.szGameMode == b"RACE":
                    # Read replay
                    with open(replay_p, "rb") as replay_f:
                        replay_d = bytearray(replay_f.read())

                    record_score, player_name = get_min_score_and_player_name(replay_header)

                    player_name = re.sub(r"\^\d", "", player_name)
                    player_name = unidecode(player_name)
                    player_name = sanitize(player_name)

                    record_time_s = format_score_as_string(record_score)

                    replay_name_new = f'[{info["szMapTitle"]}]{record_time_s}({player_name})'
                    replay_p_new = os.path.join(dir, replay_name_new + ".rep")

                    # If any time was set, rename the replay
                    # Avoid renaming replays that are already correctly named
                    if record_score < INT32_MAX and replay_name_new != replay_name:
                        # Avoid overwriting other replays
                        if os.path.isfile(replay_p_new):
                            for i in range(2, 1000):
                                if not os.path.isfile(os.path.join(dir, replay_name_new + f'_{i}' + ".rep")):
                                    replay_name_new += f'_{i}'
                                    replay_p_new = os.path.join(dir, replay_name_new + ".rep")
                                    break

                        # Rename the replay
                        os.rename(replay_p, replay_p_new)
                        data["replays"][data["replays"].index(replay_name)] = replay_name_new

                        REPLAYS_RENAMED = True

                        replay_p = replay_p_new
                        replay_name = replay_name_new

                        replay_name_wrapped = wrap_lua_ident(replay_name)

            data["info"][replay_name_wrapped] = info

            # Add workshop ID to IDs if not already present
            if info["workshopId"] != 0 and info["workshopId"] not in data["ids"]:
                data["ids"].append(info["workshopId"])

        except Exception as e:
            traceback.print_exc()
            print("Exception occurred:", replay_name)
            print("")
            BROKEN_REPLAYS.append(replay_name)

    # Re-gather replay names for display since some may have been renamed
    if REPLAYS_RENAMED:
        entries = os.listdir(dir)
        data["replays"] = [Path(entry).stem for entry in entries if os.path.isfile(os.path.join(dir, entry)) and entry.endswith(".rep") and skip_if_invalid_and_no_renaming(entry)]

    # Don't display broken replays to user
    data["replays"] = [x for x in data["replays"] if x not in BROKEN_REPLAYS]
    data["replays"].sort()

    for folder_name in folders:
        folder_name_wrapped = wrap_lua_ident(folder_name)
        data["folders"][folder_name_wrapped] = navigate(prev, dirs + [folder_name])

    return data


def update():
    prev = read_prev_data()

    data = navigate(prev, [])

    if prev != lua.decode(lua.encode(data)):
        write_new_data(data)


if __name__ == "__main__":
    print("Reflex Replay Browser Script 202201200152 by Donald")
    print("Indexing a lot of replays may take a while, be patient...")

    if "-p" in sys.argv and not process_exists("reflex.exe"):
        start_reflex()

    while True:
        if "-p" in sys.argv:
            if not process_exists("reflex.exe"):
                print("Could not find Reflex process, quitting...")
                time.sleep(1)
                sys.exit()

        update()
        time.sleep(cfg["FILE_SCANNING_INTERVAL_SECONDS"])
