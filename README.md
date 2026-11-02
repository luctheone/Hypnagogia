# Hypnagogia

**Keep your Mac—and the agents running on it—working at the edge of sleep.**

Hypnagogia is a small, local-only macOS menu-bar app that puts two sleep controls behind a clear interface:

- **Prevent idle sleep** starts Hypnagogia's own `caffeinate` process. The assertion ends when you switch it off or quit Hypnagogia.
- **Disable all system sleep** changes macOS's persistent `pmset disablesleep` setting. On supported Macs, this also blocks lid-triggered and manual sleep. macOS requests administrator approval, and the setting remains active after Hypnagogia quits or the Mac restarts.

Hypnagogia reads the existing system state when it launches. It never changes a setting until you use a switch.

> [!WARNING]
> Disabling system sleep can drain the battery and build heat, particularly with the lid closed. Never leave a running Mac inside a bag or on a soft surface. Hardware behavior varies, and macOS thermal and low-battery protections still take priority.

## Requirements

- macOS 13 or newer
- Apple silicon or Intel Mac
- Apple's Command Line Tools or Xcode when building from source

Hypnagogia has no third-party runtime dependencies.

## Build and run

```sh
git clone https://github.com/luctheone/Hypnagogia.git
cd Hypnagogia
./Scripts/check.sh
./Scripts/build-app.sh
unzip -q dist/Hypnagogia.zip -d dist
open dist/Hypnagogia.app
```

The build script creates an ad-hoc-signed `dist/Hypnagogia.zip` locally. Drag the unpacked app to `/Applications` if you want to keep it.

There is currently no notarized binary release. Building locally means the executable comes directly from the source you inspected.

## Use it

After opening Hypnagogia, look for its cup, moon, shield, or question-mark icon in the menu bar. The app intentionally has no Dock icon or conventional app window.

1. Use **Prevent idle sleep** for a temporary, app-owned session.
2. Optionally enable **Keep display on too**.
3. Use **Disable all system sleep** only when you need the persistent override. Approve the standard macOS administrator prompt.
4. Switch the persistent override off before deleting Hypnagogia if you want normal sleep restored.

If Hypnagogia is unavailable while persistent sleep disabling is active, restore normal sleep from Terminal:

```sh
sudo /usr/bin/pmset -a disablesleep 0
```

## Exactly what it runs

Temporary mode starts this fixed process, adding `-d` only when **Keep display on too** is enabled:

```text
/usr/bin/caffeinate -i [-d] -w <Hypnagogia process ID>
```

The process-ID binding makes the assertion disappear if Hypnagogia exits unexpectedly. `-i` prevents idle system sleep on either power source, but it does not override closing a laptop lid or choosing Sleep manually.

Persistent mode runs one of two fixed commands through macOS's administrator authorization dialog:

```text
/usr/bin/pmset -a disablesleep 1
/usr/bin/pmset -a disablesleep 0
```

Hypnagogia rereads `pmset -g` after every change and displays the actual resulting state instead of trusting the command's exit status.

## Privacy and security

Hypnagogia:

- does not connect to the network;
- does not collect analytics or telemetry;
- does not accept arbitrary shell input;
- does not store credentials;
- does not install a privileged helper; and
- asks macOS to authorize only one of the two fixed `pmset` commands above.

The persistent setting is deliberately not reset when Hypnagogia quits because it may have existed before the app launched. See [SECURITY.md](SECURITY.md) for reporting security problems.

## Contributing

Bug reports and focused pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing power-management behavior.

## License

Hypnagogia is available under the [MIT License](LICENSE).

The app-icon artwork is generated from original geometry in `Scripts/generate-icon.swift` and is covered by the same license.
