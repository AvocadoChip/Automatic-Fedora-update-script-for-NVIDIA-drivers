#!/bin/bash

# Initialize change tracker
CHANGES_MADE=false

# --- SELF-SPAWN LOGIC ---
if [ "$1" != "run" ]; then
    konsole -e /bin/bash -c "$0 run"
    exit 0
fi

# --- 1. PRIVILEGE ELEVATION ---
if [ "$EUID" -ne 0 ]; then
    echo "NVIDIA Maintenance Tool: Requesting administrative privileges..."
    exec sudo "$0" "$@"
fi

# --- 2. FUNCTIONS ---
finish() {
    local exit_code=$1
    echo -e "\n--- Process Finished ---"

    if [ "$CHANGES_MADE" = true ]; then
        echo "------------------------------------------------"
        echo "What would you like to do now?"
        echo "  [rb] REBOOT system (Requires typing 'rb')"
        echo "  [q]  EXIT terminal (Default - just press Enter)"
        echo "------------------------------------------------"
        
        while true; do
            echo "Selection: "
            read -r response
            response=${response:-q}

            case "$response" in
                [rR][bB])
                    echo "Rebooting now..."
                    reboot
                    ;;
                [qQ])
                    echo "Exiting..."
                    exit "$exit_code"
                    ;;
                *)
                    echo "Invalid input. Please type 'rb' to reboot or 'q' to exit."
                    echo "" # Adds a newline before asking again
                    ;;
            esac
        done
    else
        # If nothing was done, use the simple exit
        read -n 1 -s -r -p "Press any key to close this window..."
        echo ""
        exit "$exit_code"
    fi
}

confirm() {
    read -r -p "${1:-Are you sure?} [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

echo "################################################"
echo "#      NVIDIA Complete Driver Utility          #"
echo "################################################"

# --- 3. PRE-FLIGHT ---
if ! lspci | grep -iE 'vga|3d' | grep -iq nvidia; then
    echo "Error: No NVIDIA GPU detected. Is the card seated correctly?"
    finish 1
fi

if mokutil --sb-state 2>/dev/null | grep -q "enabled"; then
    echo "(!) NOTICE: Secure Boot is ENABLED."
    echo "Drivers will be installed, but you MUST sign them or disable Secure Boot"
    echo "in your BIOS for the GPU to actually turn on."
    echo "------------------------------------------------"
fi

# --- 4. REPO SETUP ---
if ! dnf repolist | grep -q "rpmfusion-nonfree-nvidia-driver"; then
    echo "Required repositories are missing."
    if confirm "Enable RPM Fusion (Free/Non-Free) and NVIDIA repos?"; then
        dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                       https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        dnf config-manager --set-enabled rpmfusion-nonfree-nvidia-driver
        dnf makecache
    else
        echo "Cannot proceed without RPM Fusion. Exiting."
        finish 1
    fi
fi

# --- 5. INSTALLATION / REPAIR ---
if ! rpm -q xorg-x11-drv-nvidia &>/dev/null; then
    echo "NVIDIA drivers are not currently installed."
    if confirm "Perform a full installation (includes 32-bit libs for Steam/Gaming)?"; then
        echo "Installing drivers, CUDA, and kernel headers..."
        dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda \
                       xorg-x11-drv-nvidia-libs.i686 kernel-devel-$(uname -r) kernel-headers
        
        echo "Forcing kernel module build..."
        akmods --force
        dracut --force
        CHANGES_MADE=true
        echo "Done."
    fi
fi

# --- 6. UPDATE CHECK ---
echo "Checking for NVIDIA package updates..."
dnf check-update *nvidia* &>/dev/null
if [ $? -eq 100 ]; then
    echo "Updates are available."
    if confirm "Would you like to upgrade the NVIDIA drivers now?"; then
        dnf upgrade -y *nvidia*
        dnf install -y kernel-devel-$(uname -r)
        echo "Rebuilding modules for the updated version..."
        akmods --force
        CHANGES_MADE=true
        echo "Update successful."
    fi
else
    echo "Everything is up to date."
fi

# Final check
if modinfo nvidia &>/dev/null; then
    echo -e "\n[SUCCESS] NVIDIA module is present in the system."
else
    echo -e "\n[WARNING] Module 'nvidia' not found."
fi

finish 0
