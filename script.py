import os
import re
import sys
import time
import json
import ctypes
import psutil
import subprocess

from config import cfg
from datetime import datetime
from slpp import slpp as lua

sys.stdout.reconfigure(encoding='utf-8')

SKIPPED_REPLAYS = []

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


def skip_if_invalid(replay_name):
    """
    Determines whether or not a replay should be skipped based on its name. If
    a replay name cannot be properly printed by Reflex, it must be skipped
    :param replay_name: The replay name to be checked
    :return: True or False depending on if the replay is valid or not
    """

    global SKIPPED_REPLAYS

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
    # Find the maximum timecode contained in the replay

    # For this, start at the end of the replay and store the current 4 byte sequence at i_ts
    # and compare with the byte sequence at i_neg. If the fuzzy logic (see below)
    # thinks they might be timestamps based on their content and their differences, it's considered a match

    i_ts = len(replay_d) - 4

    for x in range(0, 500): # i_ts
        num_matches = 0

        i_neg = i_ts - 4

        byte_seq_1 = replay_d[i_ts : i_ts + 4]

        for y in range(0, 500): #i_neg
            byte_seq_2 = replay_d[i_neg : i_neg + 4]

            # Check if the two byte sequences have differing first byte,
            # but matching last byte
            if (byte_seq_1[0:1] != byte_seq_2[0:1]) and (byte_seq_1[3:4] == byte_seq_2[3:4]):
                ts_1 = ctypes.c_uint32.from_buffer(byte_seq_1).value
                ts_2 = ctypes.c_uint32.from_buffer(byte_seq_2).value

                # Check if the difference between the byte sequences is small
                # Some other fuzzy logic here, too
                difference_1 = abs(ts_1 - ts_2)

                if ts_1 > min_tc and difference_1 < 96:
                    num_matches += 1

                if num_matches > 4:
                    return ts_1
            i_neg -= 1
        i_ts -= 1

    print("Could not find confident maximum timecode")
    return 2147483647


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

    # For this, store the current 4 byte sequence at i_ts, and compare with byte sequences at
    # i_pos and i_neg. If the fuzzy logic (see below) thinks they might be timestamps
    # based on their content and their differences, it's considered a match

    i_ts = min_score_index - 4
    i_pos = min_score_index + 4
    min_score_timestamp = -1

    for x in range(0, 250): # i_ts
        num_matches = 0

        byte_seq_1 = replay_d[i_ts : i_ts + 4]

        i_neg = i_ts - 4
        i_pos = i_ts + 4

        for y in range(0, 250): # i_neg
            byte_seq_2 = replay_d[i_neg : i_neg + 4]

            for z in range(0, 250): # i_pos
                byte_seq_3 = replay_d[i_pos : i_pos + 4]

                # Check if the two byte sequences have differing first byte,
                # but matching last byte
                if (byte_seq_1[0:1] != byte_seq_2[0:1]) and (byte_seq_1[0:1] != byte_seq_3[0:1]) and (byte_seq_1[3:4] == byte_seq_2[3:4]) and (byte_seq_1[3:4] == byte_seq_3[3:4]):
                    ts_1 = ctypes.c_uint32.from_buffer(byte_seq_1).value
                    ts_2 = ctypes.c_uint32.from_buffer(byte_seq_2).value
                    ts_3 = ctypes.c_uint32.from_buffer(byte_seq_3).value

                    # Check if the difference between the byte sequences is small, and if they fit within the timecode range
                    difference_1 = ts_1 - ts_2
                    difference_2 = ts_1 - ts_3

                    if difference_1 < 96 and difference_2 < 96:
                        if ts_1 > min_tc and ts_1 < max_tc:
                            num_matches += 1

                if num_matches > 3:
                    min_score_timestamp = byte_seq_1

                    # Adjust timestamp by subtracting run duration
                    # Give it a 1000ms buffer
                    ts = ctypes.c_uint32.from_buffer(min_score_timestamp).value
                    ts -= (min_score + 1000)

                    return ts
                i_pos += 1
            i_neg -= 1
        i_ts -= 1

    print("Could not find confident PB timecode")
    return 0


def get_timecode(replay_header, replay_d):
    # Get best score
    min_score = 2147483647

    for x in replay_header.players:
        if x.score != 0 and x.score < min_score:
            min_score = x.score

    # If no time has been set, there's no timestamp to find
    if min_score == 0:
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

    info["timecode"] = get_timecode(replay_header, replay_d)
    info["workshopId"] = replay_header.workshopId
    info["epochStartTime"] = datetime.utcfromtimestamp(replay_header.epochStartTime).strftime('%Y-%m-%d %H:%M:%S UTC')
    info["szMapTitle"] = replay_header.szMapTitle.decode("utf-8")

    return info


def navigate(prev, dirs):
    data = {"folders": {}, "replays": [], "ids": [], "info": {}}

    dir = os.path.join(cfg["REPLAY_DIR"], *dirs)

    entries = os.listdir(dir)

    folders = [entry for entry in entries if os.path.isdir(os.path.join(dir, entry))]
    replays = [entry for entry in entries if os.path.isfile(os.path.join(dir, entry)) and entry.endswith(".rep") and skip_if_invalid(entry)]

    data["replays"] = [entry[:-4] for entry in replays]

    for x in data["replays"]:
        x_wrapped = wrap_lua_ident(x)

        replay_p = os.path.join(dir, x + ".rep")

        # Try to get info from previous data
        info = get_info_in_prev_data(prev, dirs, x)

        # If replay is new, calculate info ourselves
        if info is None:
            info = get_replay_info(replay_p)

        data["info"][x_wrapped] = info

        # Add workshop ID to IDs if not already present
        if info["workshopId"] != 0 and info["workshopId"] not in data["ids"]:
            data["ids"].append(info["workshopId"])

    for x in folders:
        x_wrapped = wrap_lua_ident(x)

        data["folders"][x_wrapped] = navigate(prev, dirs + [x])

    return data


def update():
    prev = read_prev_data()

    data = navigate(prev, [])

    if prev != lua.decode(lua.encode(data)):
        print("Finished.")
        write_new_data(data)


if __name__ == "__main__":
    print("Reflex Replay Browser Script 202012231148 by Donald")
    print("Indexing replays may take a while, be patient...")

    delay = 20

    if "-p" in sys.argv and not process_exists("reflex.exe"):
        start_reflex()

    while True:
        if "-p" in sys.argv:
            if process_exists("reflex.exe"):
                update()
                time.sleep(delay)
            else:
                print("Could not find Reflex process, quitting...")
                time.sleep(1)
                sys.exit()
        else:
            update()
            time.sleep(delay)
