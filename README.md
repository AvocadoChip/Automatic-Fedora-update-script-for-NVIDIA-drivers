# AutoChip
NVIDIA Complete Driver Utility  -  a short and simple script that updates your NVIDIA drivers automatically!

## Follow the steps below to ensure correct implimentation

## Best alternative for automatic install and managment
1. Enable required repository
   ```
   sudo dnf copr enable avocadochip/AutoChip
   ```

2. Intall program via dnf (this downloads AutoChip onto your computer for later use)
   ```
   sudo dnf install autochip
   ```

3. Open the program at any time by either opening it through the GU (search), or running this command in any terminal:
   ```
   autochip
   ```

## Signing the drivers (THIS IS CRUTIAL IF SECURE BOOT IS ENABLED!)

### Step 1: Open a terminal and run the following commands
1. first you have to download all the dependencies:
   ```
   sudo dnf install kmodtool akmods mokutil openssl
   ```

2. Generate your personal key (used to sign the drivers):
   ```
   sudo kmodgenca -a
   ```

3. Import the keys to the system:
   ```
   sudo mokutil --import /etc/pki/akmods/certs/public_key.der
   ```
   NOTE! It will ask you to create a password. Make it simple. You will only need to use this password once.

### Step 2: Enrollment
1. reboot your computer. After reboot a blue screen will show up (MOK Manager). When it does, click any button within 10 seconds to enter the setup.
   ```
   sudo reboot
   ```

2. The menu steps:
   * Select Enroll MOK
   * Select Continue
   * Select Yes
   * Enter the password you created in step 1 (Important! You won't see anything while typing the password, just keep typing and press enter when done)
   * select reboot

3. You are now done signing the drivers! You 


## Running the program temporarily (no install required)

### Step 1: Open a terminal in the desktop and copy this command:
```
sudo curl -s https://github.com/AvocadoChip/AutoChip/releases/download/Release-2.0/AutoChip.sh | bash
```

### Step 2: Follow the given instructions
The program is very straightforward, and explains everything along the way.
