#!/usr/bin/env python3
"""Sinh audio phần Nghe M3 từ transcript trong assets/data/m3/set_*.json.

Dùng giọng đọc có sẵn của macOS (`say`) và ffmpeg, mỗi nhóm câu hỏi ra một file
assets/audio/m3/<groupId>.m4a. Chạy lại khi sửa transcript:

    cd nhom04-65ktpm/src
    python3 tool/m3_generate_audio.py          # chỉ tạo file còn thiếu
    python3 tool/m3_generate_audio.py --force  # tạo lại tất cả
"""

import glob
import json
import os
import subprocess
import sys
import tempfile

VOICES = {"M": "Daniel", "W": "Samantha", "N": "Karen"}
RATE = "165"  # từ/phút, chậm hơn mặc định cho trình độ B1
GAP_SECONDS = 0.45
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def synth_group(group, out_path):
    with tempfile.TemporaryDirectory() as tmp:
        parts = []
        for i, line in enumerate(group["transcript"]):
            part = os.path.join(tmp, f"{i:03d}.aiff")
            voice = VOICES.get(line["speaker"], VOICES["N"])
            subprocess.run(
                ["say", "-v", voice, "-r", RATE, "-o", part, line["text"]],
                check=True,
            )
            parts.append(part)

        inputs, filters = [], []
        for i, part in enumerate(parts):
            inputs += ["-i", part]
            filters.append(
                f"[{i}:a]aresample=22050,aformat=channel_layouts=mono,"
                f"apad=pad_dur={GAP_SECONDS}[a{i}]"
            )
        joined = "".join(f"[a{i}]" for i in range(len(parts)))
        filters.append(f"{joined}concat=n={len(parts)}:v=0:a=1[out]")
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", *inputs,
             "-filter_complex", ";".join(filters), "-map", "[out]",
             "-c:a", "aac", "-b:a", "48k", out_path],
            check=True,
        )


def main():
    force = "--force" in sys.argv
    made = 0
    for path in sorted(glob.glob(os.path.join(ROOT, "assets/data/m3/set_*.json"))):
        with open(path, encoding="utf-8") as f:
            exam = json.load(f)
        for section in exam["sections"]:
            for group in section.get("groups", []):
                audio = group.get("audio")
                if not audio:
                    continue
                out_path = os.path.join(ROOT, audio)
                if os.path.exists(out_path) and not force:
                    continue
                os.makedirs(os.path.dirname(out_path), exist_ok=True)
                synth_group(group, out_path)
                made += 1
                print("created", audio)
    print(f"done, {made} file(s) created")


if __name__ == "__main__":
    main()
