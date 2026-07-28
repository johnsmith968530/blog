#!/usr/bin/env zsh

# $Source: /home/x/Dropbox/2/src/blog/2026/07/28/src/RCS/update-and-reboot.zsh,v $
# $Date: 2026/07/28 22:11:49 $
# $Revision: 1.1 $

# update-and-reboot.zsh — for Xubuntu machines
#
# Runs, in order, stopping at the first failure:
#   1. flatpak update (only if flatpak is installed)
#   2. snap refresh   (snap's update/upgrade command)
#   3. apt update && apt upgrade -y
#   4. reboot
#
# Usage: chmod +x update-and-reboot.zsh && ./update-and-reboot.zsh
# (Run as a normal user; the script calls sudo where needed.)

# Cache sudo credentials up front so later steps don't stall.
sudo -v || { print -u2 "ERROR: sudo authentication failed."; exit 1 }

# --- 1. Flatpak -------------------------------------------------------------
if (( $+commands[flatpak] )); then
    print "==> [1/4] flatpak update -y"
    if ! flatpak update -y; then
        print -u2 "ERROR: flatpak update failed. Stopping (snap, apt, and reboot skipped)."
        exit 1
    fi
else
    print "==> [1/4] flatpak not installed — skipping."
fi

# --- 2. Snap ----------------------------------------------------------------
print "==> [2/4] snap refresh"
if ! sudo snap refresh; then
    print -u2 "ERROR: snap refresh failed. Stopping (apt and reboot skipped)."
    exit 1
fi

# --- 3. APT -----------------------------------------------------------------
print "==> [3/4] apt update"
if ! sudo apt update; then
    print -u2 "ERROR: apt update failed. Stopping (upgrade and reboot skipped)."
    exit 1
fi

print "==> [3/4] apt upgrade -y"
if ! sudo apt upgrade -y; then
    print -u2 "ERROR: apt upgrade failed. Reboot cancelled."
    exit 1
fi

# --- 4. Reboot --------------------------------------------------------------
print "==> [4/4] All updates succeeded. Rebooting..."
sudo reboot

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
