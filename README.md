# artix-installer

![](https://img.shields.io/badge/OS-Artix%20Linux-blue?logo=Artix+Linux)

A simple installer for Artix Linux. Supports OpenRC and dinit.

## Usage
1. Boot into the Artix live disk (the login and password are both `artix`).
2. Connect to the internet. Ethernet is setup automatically, and wifi is done with something like:
```
sudo rfkill unblock wifi
sudo ip link set wlan0 up
connmanctl
```
In Connman, use: `agent on`, `scan wifi`, `services`, `connect wifi_NAME`, `quit`

3. Acquire the install scripts:
```bash
curl -OL https://github.com/krzyczak/artix-install/raw/refs/heads/master/artix-install-2.3.0-1-x86_64.pkg.tar.zst
pacman -U artix-install-2.3.0-1-x86_64.pkg.tar.zst
```

4. Run
`artix-install` -> normal installation run
`artix-install artix-install.conf` -> run with previously saved config. Example is in [artix-install.example.conf](artix-install.example.conf)

5. When everything finishes, `poweroff`, remove the installation media, and boot into Artix. Post-installation networking is done with Connman.

### Preinstallation

* ISO downloads can be found at [artixlinux.org](https://artixlinux.org/download.php)
* ISO files can be burned to drives with `dd` or something like Etcher.
* `sudo dd bs=4M if=/path/to/artix.iso of=/dev/sd[drive letter] status=progress`
* A better method these days is to use [Ventoy](https://www.ventoy.net/en/index.html).
