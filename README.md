## Supported OS
macOS only.

## Required commands
- cmake
- openssl

These commands can be installed via HomeBrew, like `brew install cmake openssl`.

## Usage
Download afc2d.sh and run the following commands:
```
chmod +x afc2d.sh
./afc2d.sh
```
After the whole process of this script, you will see `afc2d_patched.deb` file and `afc2d` directory.
All you need is `afc2d_patched.deb`, so you can remove `afc2d`.

Transport created deb file to your iDevice, and run the following commands in iTerm2 or via SSH:
```
dpkg -i afc2d_patched.deb
killall -9 lockdownd
```
