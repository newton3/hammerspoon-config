#!/usr/bin/env python3
"""Most-visited URLs from Chrome + Safari history -> candidates for new PWA/URL
hotkeys. Copies each DB first (Chrome locks its file while running; Safari needs
Full Disk Access). Nothing is modified.

Usage:
    python3 tools/browser_history.py [--top 40]
"""
import argparse, atexit, os, shutil, sqlite3, tempfile

HOME = os.path.expanduser("~")
CHROME = f"{HOME}/Library/Application Support/Google/Chrome/Default/History"
SAFARI = f"{HOME}/Library/Safari/History.db"


def copy_db(path):
    if not os.path.exists(path):
        return None
    tmp = tempfile.mkdtemp(prefix="hist_")
    atexit.register(shutil.rmtree, tmp, ignore_errors=True)
    dst = os.path.join(tmp, os.path.basename(path))
    try:
        for suffix in ("", "-wal", "-shm"):
            if os.path.exists(path + suffix):
                shutil.copy2(path + suffix, dst + suffix)
    except PermissionError:
        return "DENIED"
    return dst


def chrome(top):
    db = copy_db(CHROME)
    if db is None:
        print("Chrome: history not found."); return
    if db == "DENIED":
        print("Chrome: permission denied (unexpected)."); return
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    rows = conn.execute(
        "SELECT url, title, visit_count FROM urls "
        "WHERE visit_count > 0 ORDER BY visit_count DESC LIMIT ?", (top,)).fetchall()
    print(f"\n=== Chrome — top {top} by visit count ===")
    print(f"{'Visits':>7}  {'Title':40}  URL")
    for url, title, vc in rows:
        print(f"{vc:>7}  {(title or '')[:40]:40}  {url[:90]}")


def safari(top):
    db = copy_db(SAFARI)
    if db is None:
        print("\nSafari: history not found."); return
    if db == "DENIED":
        print("\nSafari: permission denied — grant Full Disk Access to your terminal and retry.")
        return
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    rows = conn.execute(
        "SELECT hi.url, hi.visit_count "
        "FROM history_items hi "
        "WHERE hi.visit_count > 0 ORDER BY hi.visit_count DESC LIMIT ?", (top,)).fetchall()
    print(f"\n=== Safari — top {top} by visit count ===")
    print(f"{'Visits':>7}  URL")
    for url, vc in rows:
        print(f"{vc:>7}  {url[:100]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=40)
    args = ap.parse_args()
    print("Tip: URLs you hit often but have no hotkey for are good shortcut candidates.")
    chrome(args.top)
    safari(args.top)


if __name__ == "__main__":
    main()
