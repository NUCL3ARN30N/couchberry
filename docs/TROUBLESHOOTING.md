# Troubleshooting

## `Permission denied` or `bad interpreter: /bin/bash^M` when running a script

- `Permission denied`: the script lost its executable flag (common after unzipping or copying from Windows). Fix:

  ```bash
  chmod +x install.sh uninstall.sh steamlink-manager.sh
  ```

- `bad interpreter: /bin/bash^M`: the file has Windows line endings. Fix:

  ```bash
  sed -i 's/\r$//' *.sh kiosk/steamlink-kiosk*
  ```

## Getting access when the screen shows only Steam Link

- **SSH** (recommended): enable SSH in Raspberry Pi Imager, or later with `sudo raspi-config` → Interface Options → SSH.
- **Text console:** attach a keyboard and press `Ctrl+Alt+F2`.

## No sound

Check which output is the default:

```bash
wpctl status
```

Under `Audio → Sinks`, the sink marked with `*` should be "Built-in Audio Digital Stereo (HDMI)". If the headphone jack ("Built-in Audio Stereo") has the `*`, set HDMI manually using its ID:

```bash
wpctl set-default <id>
wpctl set-mute <id> 0
wpctl set-volume <id> 1.0
```

The kiosk does this automatically at each start; if it did not work, the HDMI sink probably did not appear within 30 seconds. Also check:

- The TV volume and selected HDMI input.
- HDMI port: use the one next to the USB-C power port (HDMI-0) if you only use one display.
- Play a test sound: `pw-play /usr/share/sounds/alsa/Front_Center.wav`

## A terminal says "Updating Steam Controller polling rate... Press return to continue"

The USB polling rate is not 2 at boot. Check:

```bash
cat /sys/module/usbhid/parameters/mousepoll   # should print 2
grep -o 'usbhid.mousepoll=2' /proc/cmdline    # should print it
```

If the second command prints nothing, re-run `./install.sh --no-upgrade --no-xpadneo`, or add ` usbhid.mousepoll=2` to the end of the single line in `/boot/firmware/cmdline.txt`, then reboot. Note that `cmdline.txt` must remain one line.

## Black screen / never reaches Steam Link

From SSH or the `Ctrl+Alt+F2` console:

```bash
ps -eo pid,args | grep -E 'labwc|steamlink|shell'   # kiosk running?
sudo systemctl status lightdm
journalctl -b -u lightdm --no-pager | tail -50
```

Steam Link's real process is named `shell` once it has started.

To get the normal desktop back immediately:

```bash
./uninstall.sh
```

or restore the backup by hand:

```bash
sudo cp /etc/lightdm/lightdm.conf.bak-steamlink /etc/lightdm/lightdm.conf
sudo reboot
```

## Dropped frames / stutter

- Use wired Ethernet.
- Run `./steamlink-manager.sh` and switch to the beta build (or back to stable).
- Lower the stream resolution or bitrate in Steam Link's settings.

## Controller issues

- Steam Controller: connect the USB puck; no extra drivers are needed.
- Xbox controllers over Bluetooth: re-run `./install.sh --with-xpadneo --no-upgrade`. If the DKMS build fails, make sure `linux-headers-$(uname -r)` is installed.

## Wrong keyboard layout in the kiosk

The installer copies `~/.config/labwc/environment` (set up by `raspi-config` / the desktop) to `~/.config/labwc-kiosk/environment`. If you change the layout later, copy it again.

## Restarting Steam Link without rebooting

Steam Link is restarted automatically when it exits. To restart it:

```bash
pkill -x shell
```

To restart the whole kiosk session:

```bash
sudo systemctl restart lightdm
```
