#!/usr/bin/env python3
"""Screen Time (knowledgeC) app-usage report — "where I spend most time".

Reads macOS's local knowledgeC.db. REQUIRES Full Disk Access for the terminal
running this (System Settings -> Privacy & Security -> Full Disk Access).

The DB schema drifts across macOS versions, so this script DISCOVERS the schema
at runtime and fails loudly rather than trusting hard-coded names.

Usage:
    python3 tools/screentime.py [--days 30] [--stream /app/usage] [--json]
"""
import argparse, atexit, os, shutil, sqlite3, sys, tempfile, json
from datetime import datetime, timedelta

MAC_EPOCH = 978307200  # seconds between 1970-01-01 and 2001-01-01 (Mac absolute)
DB = os.path.expanduser("~/Library/Application Support/Knowledge/knowledgeC.db")
USAGE_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "usage")


def copy_db():
    """Copy the DB (+ wal/shm) to a temp dir so we never touch the live file."""
    if not os.path.exists(DB):
        sys.exit(f"knowledgeC.db not found at {DB}")
    tmp = tempfile.mkdtemp(prefix="kc_")
    atexit.register(shutil.rmtree, tmp, ignore_errors=True)
    dst = os.path.join(tmp, "knowledgeC.db")
    try:
        for suffix in ("", "-wal", "-shm"):
            src = DB + suffix
            if os.path.exists(src):
                shutil.copy2(src, dst + suffix)
    except PermissionError:
        sys.exit("Permission denied reading knowledgeC.db.\n"
                 "Grant Full Disk Access to your terminal:\n"
                 "  System Settings -> Privacy & Security -> Full Disk Access -> add your terminal, then restart it.")
    return dst


def discover(conn):
    """Verify ZOBJECT + expected columns exist; return the available streams."""
    cur = conn.cursor()
    tables = {r[0] for r in cur.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    if "ZOBJECT" not in tables:
        sys.exit("Schema changed: no ZOBJECT table. Inspect with: sqlite3 <db> '.tables'")
    cols = {r[1] for r in cur.execute("PRAGMA table_info(ZOBJECT)")}
    needed = {"ZSTREAMNAME", "ZVALUESTRING", "ZSTARTDATE", "ZENDDATE"}
    missing = needed - cols
    if missing:
        sys.exit(f"Schema changed: ZOBJECT missing {missing}. Columns present: {sorted(cols)}")
    streams = [r[0] for r in cur.execute(
        "SELECT DISTINCT ZSTREAMNAME FROM ZOBJECT WHERE ZSTREAMNAME LIKE '/app/%'")]
    return streams


def report(conn, stream, days):
    cutoff = (datetime.now() - timedelta(days=days)).timestamp() - MAC_EPOCH
    cur = conn.cursor()
    rows = cur.execute(
        "SELECT ZVALUESTRING AS app, SUM(ZENDDATE - ZSTARTDATE) AS secs, COUNT(*) AS n "
        "FROM ZOBJECT WHERE ZSTREAMNAME = ? AND ZSTARTDATE > ? "
        "AND ZVALUESTRING IS NOT NULL "
        "GROUP BY ZVALUESTRING ORDER BY secs DESC", (stream, cutoff)).fetchall()
    return [(app, secs or 0, n) for app, secs, n in rows]


def human(secs):
    h = int(secs // 3600); m = int((secs % 3600) // 60)
    return f"{h}h {m:02d}m" if h else f"{m}m"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=30)
    ap.add_argument("--stream", default=None, help="default: /app/usage, else /app/inFocus")
    ap.add_argument("--json", action="store_true", help="also write usage/screentime.json")
    ap.add_argument("--top", type=int, default=30)
    args = ap.parse_args()

    db = copy_db()
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    streams = discover(conn)
    if not streams:
        sys.exit("No /app/* streams found in knowledgeC.db on this macOS version.")

    stream = args.stream
    if stream is None:
        stream = "/app/usage" if "/app/usage" in streams else (
                 "/app/inFocus" if "/app/inFocus" in streams else streams[0])
    print(f"# Screen Time — last {args.days} days  (stream: {stream})")
    print(f"# available streams: {', '.join(streams)}\n")

    rows = report(conn, stream, args.days)
    if not rows:
        print("(no rows — try --stream /app/inFocus or a larger --days)")
        return
    total = sum(r[1] for r in rows)
    print(f"{'App / bundle id':45} {'Time':>10} {'Sessions':>9}")
    print("-" * 66)
    for app, secs, n in rows[:args.top]:
        print(f"{app[:45]:45} {human(secs):>10} {n:>9}")
    print("-" * 66)
    print(f"{'TOTAL':45} {human(total):>10}")

    if args.json:
        os.makedirs(USAGE_DIR, exist_ok=True)
        out = os.path.join(USAGE_DIR, "screentime.json")
        with open(out, "w") as f:
            json.dump({"days": args.days, "stream": stream,
                       "apps": [{"app": a, "secs": s, "sessions": n} for a, s, n in rows]}, f, indent=2)
        print(f"\nwrote {out}")


if __name__ == "__main__":
    main()
