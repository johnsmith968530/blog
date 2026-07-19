#!/usr/bin/env python3

# $Source: /home/x/Dropbox/2/src/blog/2026/07/19/src/RCS/sort_lmstudio_conversations.py,v $
# $Date: 2026/07/19 19:43:55 $
# $Revision: 1.1 $

import argparse
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Sort LM Studio conversation files into YYYY/mm/dd "
            "subdirectories according to their createdAt timestamps."
        )
    )
    parser.add_argument(
        "directory",
        nargs="?",
        type=Path,
        default=Path.home() / ".lmstudio" / "conversations",
        help="LM Studio conversations directory",
    )
    parser.add_argument(
        "--timezone",
        default="local",
        help=(
            "Timezone used to determine the calendar date. "
            'Use "local", "UTC", or an IANA name such as '
            '"Europe/Berlin" or "America/Los_Angeles". '
            'Default: "local".'
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the moves without changing anything.",
    )
    return parser.parse_args()


def resolve_timezone(name: str):
    if name.lower() == "local":
        return datetime.now().astimezone().tzinfo

    if name.upper() == "UTC":
        return timezone.utc

    try:
        return ZoneInfo(name)
    except Exception as error:
        raise ValueError(f"Unknown timezone: {name}") from error


def created_datetime(path: Path, tz) -> datetime:
    with path.open("r", encoding="utf-8") as stream:
        conversation = json.load(stream)

    created_at = conversation.get("createdAt")

    if isinstance(created_at, bool) or not isinstance(created_at, (int, float)):
        raise ValueError('missing or invalid numeric "createdAt" value')

    # LM Studio stores Unix time in milliseconds.
    return datetime.fromtimestamp(created_at / 1000, tz=tz)


def main() -> int:
    args = parse_arguments()
    root = args.directory.expanduser().resolve()

    try:
        tz = resolve_timezone(args.timezone)
    except ValueError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2

    if not root.is_dir():
        print(f"Error: directory does not exist: {root}", file=sys.stderr)
        return 2

    moved = 0
    skipped = 0
    failed = 0

    # Only inspect files immediately inside the root. Files already sorted into
    # subdirectories will therefore not be touched on subsequent runs.
    files = sorted(root.glob("*.conversation.json"))

    for source in files:
        try:
            created = created_datetime(source, tz)
            destination_directory = (
                root
                / f"{created.year:04d}"
                / f"{created.month:02d}"
                / f"{created.day:02d}"
            )
            destination = destination_directory / source.name

            if destination.exists():
                print(
                    f"SKIP: destination already exists:\n"
                    f"      {destination}",
                    file=sys.stderr,
                )
                skipped += 1
                continue

            print(f"{source} -> {destination}")

            if not args.dry_run:
                destination_directory.mkdir(parents=True, exist_ok=True)
                shutil.move(str(source), str(destination))

            moved += 1

        except (OSError, ValueError, json.JSONDecodeError) as error:
            print(f"ERROR: {source}: {error}", file=sys.stderr)
            failed += 1

    action = "Would move" if args.dry_run else "Moved"
    print(
        f"\n{action}: {moved}; skipped: {skipped}; failed: {failed}; "
        f"examined: {len(files)}"
    )

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())

# vim: set et ff=unix ft=python nocp sts=4 sw=4 ts=4:
