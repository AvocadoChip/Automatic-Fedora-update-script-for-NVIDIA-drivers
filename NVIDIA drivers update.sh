#!/bin/bash

# 1. Check if RPM Fusion is enabled (The 'Official' Fedora way)
if ! dnf repolist | grep -q "rpmfusion-nonfree-nvidia-driver"; then
    echo "Error: RPM Fusion NVIDIA repo not found. This script only uses the official repository."
    exit 1
fi

echo "--- Checking for NVIDIA Driver Updates ---"

# 2. Check for updates (using dnf5 logic if available)
CHECK_UPDATE=$(dnf check-update *nvidia* 2>/dev/null)
UPDATE_STATUS=$?

if [ $UPDATE_STATUS -eq 100 ]; then
    echo "Update found! Installing now..."
    sudo dnf upgrade *nvidia* -y
    
    echo "--- Building Kernel Module (DO NOT REBOOT) ---"
    # 3. This is the crucial part: it forces the build in the foreground
    sudo akmods --force
    
    # 4. Final verification check
    MOD_VERSION=$(modinfo -F version nvidia 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "Success! NVIDIA Driver version $MOD_VERSION is built and ready."
        echo "You can now safely reboot your system."
    else
        echo "Warning: Driver build might have failed. Check 'journalctl -xe' before rebooting."
    fi
else
    echo "Everything is up to date. No action needed."
fi
echo ""
read -p "Press Enter to close this window..."