# Hammerspoon configuration

A modular Hammerspoon setup with a searchable hotkey registry, conflict
detection, window tiling, app launchers, browser helpers, and local usage
reports.

## Install

1. Install [Hammerspoon](https://www.hammerspoon.org/) and grant Accessibility
   permission when macOS asks.
2. Clone this repository to `~/.hammerspoon`.
3. Reload Hammerspoon.

The committed configuration is safe to run as-is. To add machine-, account-,
or employer-specific settings, copy the examples:

```sh
mkdir -p ~/.hammerspoon/local_config
cp ~/.hammerspoon/examples/local_config/*.lua ~/.hammerspoon/local_config/
```

Files under `local_config/` override the public defaults and are ignored by
Git. Keep private URLs, hostnames, commands, identifiers, and absolute paths
there.

## Useful hotkeys

- `⌃⌥⌘/` opens the searchable shortcut sheet.
- `⌃⌥⌘.` shows the local usage summary.
- `⌥⌘H` reloads Hammerspoon.
- `⌃⌥⌘` plus arrows or `U/I/J/K` tiles the current window.

## Privacy

Foreground-app tracking starts automatically when Hammerspoon loads. It records
the app name, bundle ID, start/end timestamps, and duration; shortcut counts and
generated reports are also stored locally. All of this stays in the ignored
`usage/` directory and is never intended for source control. To disable
tracking, remove or comment out `tracker.start()` in `init.lua`; remove
`reports.startPeriodic()` as well to disable scheduled reports.

The optional analysis scripts under `tools/` read local browser history,
Screen Time data, or shell history. Saved reports go only under the ignored
`usage/` directory; browser and Screen Time database working copies use the
system temporary directory and are removed on normal process exit. Some tools
require Full Disk Access. The dictionary shortcut sends the entire selected
text to `dictionaryapi.dev`. Review or disable these features if that is not
acceptable for your environment.

Remote desktop support expects VNC to listen only on the remote loopback
interface; the shortcut carries it through an SSH tunnel before opening macOS
Screen Sharing.

## Remote dual-boot control

The `⇄` menubar item and `⌃⌥⇧⌘B` open the remote dual-boot controls. Both use
the same backend as the `reboot-to-windows` and `reboot-to-omarchy` terminal
commands. Dry-run is the default; live mode performs SSH and privilege checks,
shows the exact command, and requires typed confirmation in Terminal.

Copy `examples/local_config/boot_remote.conf` to
`local_config/boot_remote.conf`, fill in the two SSH targets and exact GRUB
entry names, then symlink the two scripts from `bin/` into a directory on
`PATH`. SSH key authentication is required for reliable Hammerspoon checks.
Omarchy live mode allocates a TTY when sudo needs a password. Windows must have
OpenSSH Server installed and its SSH session must be administrator-level
because `mountvol /S` requires elevation.
