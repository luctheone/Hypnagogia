# Contributing to Hypnagogia

Thanks for helping improve Hypnagogia. Keep changes small, understandable, and honest about what macOS power assertions can and cannot guarantee.

## Development setup

Hypnagogia requires macOS 13 or newer and Apple's Command Line Tools or Xcode. It has no third-party package dependencies.

```sh
./Scripts/check.sh
./Scripts/build-app.sh
```

Run both commands before opening a pull request.

## Safety rules

- Do not add arbitrary shell execution or interpolate user-controlled text into a command.
- Keep privileged operations limited to fixed, reviewable commands.
- Never store an administrator password or use `sudo -S`.
- Treat `pmset -g` as the source of truth after a change; a zero exit status is not sufficient verification.
- Do not automatically reset a persistent setting that Hypnagogia may not own.
- Do not add automated tests that mutate the host's persistent power settings.
- Keep closed-lid testing brief, ventilated, and manually supervised.

## Pull requests

Describe the user-visible behavior, the macOS versions and hardware tested, and any power setting changed during manual testing. Include tests for parser or state-machine changes. UI changes should remain keyboard-accessible and expose useful VoiceOver labels.

By contributing, you agree that your contribution is licensed under the repository's MIT License.
