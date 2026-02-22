# mouse-fixer

A lightweight macOS daemon that automatically toggles natural scrolling when a Logitech USB Receiver is connected or disconnected.

When the receiver is plugged in, natural scrolling is turned **off** (traditional mouse direction). When it's removed, natural scrolling is turned **on** (trackpad-friendly direction).

## How it works

- Uses IOKit to listen for USB device connect/disconnect events for the Logitech USB Receiver (vendor ID 1133, product ID 50475)
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
