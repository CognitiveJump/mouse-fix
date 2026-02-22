# mouse-fixer

A lightweight macOS daemon that automatically toggles natural scrolling when any external mouse is connected or disconnected.

When a mouse is plugged in (USB, Bluetooth, or BLE), natural scrolling is turned **off** (traditional mouse direction). When all mice are removed, natural scrolling is turned **on** (trackpad-friendly direction).

## How it works

- Uses IOHIDManager to detect any mouse device regardless of vendor or connection type (USB, Bluetooth, BLE)
- Tracks multiple mice — natural scrolling only re-enables when all are disconnected
- Calls the private `CGSSetSwipeScrollDirection` CoreGraphics API to change the scroll direction immediately — the same function macOS System Settings uses internally
- Persists the preference and notifies System Settings so the UI stays in sync

## Build

```bash
swiftc -o mouse-fixer main.swift -framework IOKit -framework Foundation -framework CoreGraphics
```

## Install

Copy the binary and load the LaunchAgent:

```bash
mkdir -p ~/.local/bin
cp mouse-fixer ~/.local/bin/mouse-fixer
cp com.shane.mouse-fixer.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.shane.mouse-fixer.plist
```

The daemon will start automatically on login.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.shane.mouse-fixer.plist
rm ~/Library/LaunchAgents/com.shane.mouse-fixer.plist
rm ~/.local/bin/mouse-fixer
```

## Logs

```bash
cat /tmp/mouse-fixer.log
```
