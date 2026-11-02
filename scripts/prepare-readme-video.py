#!/usr/bin/env python3
"""Prepare a lossless MP4 and a small animated README preview with FFmpeg."""

from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "recovered/dsd_ill/Slides and video/Audio + Video Max/Pong Logic Max.mkv"
VIDEO = ROOT / "media/pong-logic.mp4"
PREVIEW = ROOT / "media/pong-logic-preview.gif"


def ffmpeg(*args: str) -> None:
    subprocess.run(["ffmpeg", "-y", "-v", "error", *args], check=True)


def stream_hash(path: Path, stream: str) -> str:
    return subprocess.check_output(
        [
            "ffmpeg", "-v", "error", "-i", str(path), "-map", stream,
            "-c", "copy", "-f", "hash", "-hash", "sha256", "-",
        ],
        text=True,
    ).strip()


def main() -> None:
    VIDEO.parent.mkdir(exist_ok=True)
    # Change the container only; preserve both original encoded streams.
    ffmpeg("-i", str(SOURCE), "-map", "0", "-c", "copy", "-movflags", "+faststart", str(VIDEO))
    for stream in ("0:v:0", "0:a:0"):
        if stream_hash(SOURCE, stream) != stream_hash(VIDEO, stream):
            raise RuntimeError(f"Original stream changed: {stream}")

    # Six-second thumbnail montage; the linked full recording remains unedited.
    filters = (
        "[0:v]split=3[a][b][c];"
        "[a]trim=start=0:end=2,setpts=PTS-STARTPTS[a0];"
        "[b]trim=start=34:end=36,setpts=PTS-STARTPTS[b0];"
        "[c]trim=start=68:end=70,setpts=PTS-STARTPTS[c0];"
        "[a0][b0][c0]concat=n=3:v=1:a=0,fps=8,scale=960:-1:flags=lanczos,split[gen][use];"
        "[gen]palettegen=max_colors=128:stats_mode=diff[palette];"
        "[use][palette]paletteuse=dither=bayer:bayer_scale=3[out]"
    )
    ffmpeg("-i", str(VIDEO), "-filter_complex", filters, "-map", "[out]", "-loop", "0", str(PREVIEW))
    print("Prepared README preview; original video and audio streams are unchanged.")


if __name__ == "__main__":
    main()
