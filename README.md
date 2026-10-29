# couchberry

[![GitHub stars](https://img.shields.io/github/stars/NUCL3ARN30N/couchberry?style=for-the-badge)](https://github.com/NUCL3ARN30N/couchberry/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/NUCL3ARN30N/couchberry?style=for-the-badge)](https://github.com/NUCL3ARN30N/couchberry/network/members)
[![GitHub issues](https://img.shields.io/github/issues/NUCL3ARN30N/couchberry?style=for-the-badge)](https://github.com/NUCL3ARN30N/couchberry/issues)
[![GitHub license](https://img.shields.io/github/license/NUCL3ARN30N/couchberry?style=for-the-badge)](LICENSE)

![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-A22846?style=for-the-badge&logo=raspberrypi&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-FFBC00?style=for-the-badge&logo=wayland&logoColor=black)
![Steam](https://img.shields.io/badge/Steam%20Link-000000?style=for-the-badge&logo=steam&logoColor=white)

> Turn a Raspberry Pi 4B into a dedicated Steam Link box — power it on and it boots straight into Steam Link

The desktop is never shown, sound plays over HDMI, and Steam Link restarts itself if it ever exits.

## Quick Start

On a fresh Raspberry Pi OS (64-bit, with desktop), as your normal user:

```bash
sudo apt install -y git
git clone https://github.com/NUCL3ARN30N/couchberry.git
cd couchberry
chmod +x install.sh uninstall.sh steamlink-manager.sh
./install.sh
```

New to Linux? Follow the [step-by-step installation guide](#installation-guide) below.

## Tested Setup

| Component      | Version                                                          |
| -------------- | ---------------------------------------------------------------- |
| **Board**      | Raspberry Pi 4 Model B (Rev 1.4)                                 |
| **OS**         | Raspberry Pi OS **Trixie** (Debian 13), 64-bit, **with desktop** |
| **Kernel**     | 6.18.50+rpt-rpi-v8                                               |
| **Steam Link** | 1.0.16 (stable, apt repository)                                  |
| **Network**    | Wired Ethernet, 1080p60 over HDMI                                |
| **Controller** | Steam Controller (via the USB puck)                              |

Other setups (Pi 5, Bookworm, Lite images) are untested and may need changes.

## What It Does

| #  | Step                    | Detail                                                                                                                                                                                                                               |
| -- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1  | **Installs Steam Link** | From the official apt repository                                                                                                                                                                                                     |
| 2  | **xpadneo (optional)**  | [xpadneo](https://github.com/atar-axis/xpadneo) for Xbox controllers over Bluetooth. Trixie has no `raspberrypi-kernel-headers` package, so the installer uses `linux-headers-$(uname -r)`. This path has not been tested end to end |
| 3  | **Kiosk session**       | `steamlink-kiosk` — a bare [labwc](https://github.com/labwc/labwc) compositor with no panel, wallpaper or file manager, running only Steam Link                                                                                      |
| 4  | **Auto-login**          | Switches lightdm auto-login to that session, so the normal desktop is never shown                                                                                                                                                    |
| 5  | **HDMI audio fix**      | Applied at every boot (see below)                                                                                                                                                                                                    |
| 6  | **USB polling rate**    | Set to avoid a blocking prompt (see below)                                                                                                                                                                                           |

### Why the Audio Fix Is Needed

On a stock install the default PipeWire sink can be the **3.5 mm headphone jack**, while HDMI is a
separate, quieter sink. Steam Link plays to the default sink, so you get video with no sound.
`raspi-config nonint do_audio` does not reliably change the default with PipeWire on Trixie.

`kiosk/steamlink-kiosk-run` waits for PipeWire (up to 30 s) at each start, finds the HDMI sink with
`wpctl`, makes it the default, unmutes it and sets it to 100%. Use your TV or receiver to control the
volume. If you have both HDMI ports connected, the first HDMI sink is used.

### Why the Polling-Rate Setting Is Needed

If the USB mouse polling rate is above 2, Steam Link's launcher opens a terminal saying "Updating Steam
Controller polling rate... Press return to continue" and **waits for Enter on every boot** (the kernel
resets the value each time). Without a keyboard attached, the kiosk is stuck. `usbhid` is built into
the Pi kernel, so the fix is `usbhid.mousepoll=2` on the kernel command line
(`/boot/firmware/cmdline.txt`). With the rate already at 2, the prompt never appears.

## Installation Guide

No Linux knowledge needed. Follow the steps in order. Everything you type goes into a **terminal** (a
window where you type commands and press Enter). Lines in grey boxes are commands: copy one, paste it,
press **Enter**.

### What You Need

| Item                         | Notes                                                               |
| ---------------------------- | ------------------------------------------------------------------- |
| **Raspberry Pi 4B**          | With its power supply                                               |
| **microSD card**             | 16 GB or more, and a way to plug it into your PC                    |
| **Micro-HDMI to HDMI cable** | And a TV or monitor                                                 |
| **Ethernet cable**           | To your router — Wi-Fi works but wired is recommended for streaming |
| **Gaming PC**                | With Steam, on the same network                                     |
| **Controller**               | Steam Controller or Xbox controller                                 |
| **Keyboard and mouse**       | For the first setup; afterwards only if something goes wrong        |
| **Raspberry Pi Imager**      | On your PC: <https://www.raspberrypi.com/software/>                 |

### Step 1: Put the System on the SD Card

1. Plug the SD card into your PC and open **Raspberry Pi Imager**.
2. Follow the screenshots below. The important choices are **Raspberry Pi 4**, **Raspberry Pi OS (64-bit) with desktop** (not "Lite"), and **SSH enabled**.
3. Click **Write** and wait until it says it is finished. This erases the SD card.

<details open>
<summary>Raspberry Pi Imager walkthrough (screenshots)</summary>

**1. Choose your device:** Raspberry Pi 4

![Choose device: Raspberry Pi 4](docs/images/01-device.png)

**2. Choose the OS:** Raspberry Pi OS (64-bit), the full version *with desktop*, not Lite

![Choose OS: Raspberry Pi OS 64-bit with desktop](docs/images/02-os.png)

**3. Choose your SD card**

![Choose storage](docs/images/03-storage.png)

**4. Hostname:** give the Pi a name (for example `pi-steamlink-kiosk`)

![Customisation: hostname](docs/images/04-hostname.png)

**5. SSH:** enable SSH (recommended, since the kiosk has no desktop to fall back on)

![Customisation: enable SSH](docs/images/05-ssh.png)

**6. Summary:** check the settings, then click **Write**

![Summary screen, then Write](docs/images/06-summary.png)

The Imager layout differs slightly between versions. Remember the **username and password** you set: you need them later.
</details>

### Step 2: First Boot

1. Put the SD card into the Pi. Connect HDMI to the TV, Ethernet to the router, then the power cable last.
2. Wait for the normal Raspberry Pi desktop to appear (the first boot takes a minute or two). If a setup wizard shows up, finish it.
3. Open a terminal on the Pi: click the black **Terminal** icon in the top bar.

If you set up SSH, you can instead type commands from your PC, which is more comfortable (copy and
paste works). On your PC, open a terminal (on Windows: PowerShell) and run, replacing
`pi-steamlink-kiosk` and `pi` with the hostname and username you chose:

```bash
ssh pi@pi-steamlink-kiosk.local
```

### Step 3: Get the Files onto the Pi

Pick **one** of the two options.

**Option A (easiest): download with git.** In the Pi's terminal:

```bash
sudo apt install -y git
git clone https://github.com/NUCL3ARN30N/couchberry.git
cd couchberry
```

**Option B: download the ZIP.** On GitHub, click the green **Code** button, then **Download ZIP**.
Copy the ZIP to the Pi (for example with `scp`, a USB stick, or by downloading it in the Pi's browser).
Then in the Pi's terminal, assuming the file is in your home folder:

```bash
sudo apt install -y unzip
unzip couchberry-main.zip
cd couchberry-main
```

### Step 4: Make the Scripts Runnable (important with Option B)

Files that were zipped, copied from Windows or downloaded in a browser often lose their "executable"
flag. If you used `git clone` (Option A) this is already correct, but running the command is harmless.
Always run it:

```bash
chmod +x install.sh uninstall.sh steamlink-manager.sh
```

`chmod +x` means "allow this file to be run as a program". You can check it worked with `ls -l *.sh`:
each line should start with `-rwx`.

| Message                            | What to do                                                                                            |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **`Permission denied`**            | You skipped the `chmod +x` step above. Run it, then try again                                         |
| **`bad interpreter: /bin/bash^M`** | The files have Windows line endings. Run `sed -i 's/\r$//' *.sh kiosk/steamlink-kiosk*` and try again |
| **`No such file or directory`**    | You are in the wrong folder. Run `cd ~/couchberry` (or `cd ~/couchberry-main`) first                  |

### Step 5: Run the Installer

Make sure you are inside the folder (the one containing `install.sh`), then run it as your normal
user. **Do not put `sudo` in front.** The script asks for your password when it needs it.

```bash
./install.sh
```

| Stage              | What happens                                                                                                                              |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **System update**  | Updates the system and installs Steam Link. This can take several minutes                                                                 |
| **xpadneo prompt** | `Install xpadneo for Xbox controllers over Bluetooth? (y/n)` — press `y` only if you use an Xbox controller over Bluetooth, otherwise `n` |
| **Kiosk setup**    | Sets up the kiosk session, auto-login, and the USB polling-rate fix                                                                       |
| **Reboot prompt**  | `Reboot now? (y/n)` — press `y`                                                                                                           |

Want no questions at all? `./install.sh --no-xpadneo --no-reboot`, then reboot yourself with `sudo reboot`.

### Step 6: Check That It Works

After the reboot, the Pi should show the boot logo and then go **straight to Steam Link**, with no
desktop or taskbar. If it does, you are done with the setup.

### Step 7: Connect to Your Gaming PC

1. On the gaming PC, start **Steam** and sign in.
2. On the TV, Steam Link shows your PC. Select it.
3. Steam Link shows a **PIN**. Type it into Steam on the gaming PC when asked.
4. Pair your controller (Steam Controller: plug in the USB puck) and play.

Sound should come out of the TV. If not, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

### Something Went Wrong?

| Problem                                                        | Where to look                                      |
| -------------------------------------------------------------- | -------------------------------------------------- |
| **No Steam Link, no sound, a stuck prompt, or a black screen** | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| **You want your normal desktop back**                          | Run `./uninstall.sh` (see [Uninstall](#uninstall)) |

## Installer Options

| Option                                | Effect                                                             |
| ------------------------------------- | ------------------------------------------------------------------ |
| **`--with-xpadneo` / `--no-xpadneo`** | Install (or skip) the xpadneo Xbox Bluetooth driver without asking |
| **`--no-upgrade`**                    | Skip `apt upgrade` (still runs `apt update`)                       |
| **`--no-reboot`**                     | Don't offer to reboot at the end                                   |

The installer is safe to run again.

## Updating Steam Link / Switching to Beta

```bash
./steamlink-manager.sh
```

A small menu shows the installed version and lets you update, switch to stable, or switch to the beta
build. Try beta if you see dropped frames. The beta download URL comes from the original Steam Link
instructions and has not been re-verified recently.

## Repository Layout

| Path                            | Purpose                            | Installed to                  |
| ------------------------------- | ---------------------------------- | ----------------------------- |
| `install.sh`                    | One-shot installer                 | —                             |
| `uninstall.sh`                  | Reverts to the normal desktop      | —                             |
| `steamlink-manager.sh`          | Update / stable ↔ beta menu        | —                             |
| `kiosk/steamlink-kiosk`         | Session launcher (labwc only)      | `/usr/local/bin`              |
| `kiosk/steamlink-kiosk-run`     | Audio fix + restart-on-exit loop   | `/usr/local/bin`              |
| `kiosk/steamlink-kiosk.desktop` | Session entry for lightdm          | `/usr/share/wayland-sessions` |
| `kiosk/rc.xml`                  | Minimal labwc config               | `~/.config/labwc-kiosk`       |
| `docs/TROUBLESHOOTING.md`       | Common problems and how to recover | —                             |

Files changed outside this repo, with backups created on first run:

| File                         | Backup                       |
| ---------------------------- | ---------------------------- |
| `/etc/lightdm/lightdm.conf`  | `lightdm.conf.bak-steamlink` |
| `/boot/firmware/cmdline.txt` | `cmdline.txt.bak-steamlink`  |

## Uninstall

```bash
./uninstall.sh                      # back to the normal desktop
./uninstall.sh --remove-steamlink   # ... and remove Steam Link too
```

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md): no sound, stuck on a terminal prompt, black
screen, getting back to a desktop, and more.

## Requirements

**Hardware:** Raspberry Pi 4B, HDMI display, wired network recommended  
**OS:** Raspberry Pi OS Trixie (Debian 13), 64-bit, with desktop — not Lite  
**Host:** A gaming PC running Steam on the same network  
**Exiting:** Steam Link is relaunched whenever it exits, so you cannot quit it from the screen. Use SSH to stop things (see troubleshooting)  
**Caution:** This changes the system boot configuration. Read the scripts before running them, as you should with any script from the internet  
**Affiliation:** Not affiliated with Valve. Steam Link is Valve's software

---

Badges from [envoy1084/awesome-badges](https://github.com/envoy1084/awesome-badges)
