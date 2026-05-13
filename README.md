# AppTrap

AppTrap is a macOS utility distributed as a **System Settings preference pane** (`AppTrap.prefPane`) plus a background app (`AppTrap.app`).

- `AppTrap.prefPane` is the plugin shown in System Settings.
- `AppTrap.app` watches app deletions and offers to remove related files.

The preference pane bundles the background app so users install one `.prefPane` and get both components.

## Requirements

- **macOS 13 (Ventura) or later**
- **Xcode 15 or later** (CLI tools included)

Verify tools:

```bash
xcodebuild -version
xcode-select -p
```

## Repository layout

- `/home/runner/work/AppTrap/AppTrap/AppTrap` → background app project (`AppTrap.xcodeproj`)
- `/home/runner/work/AppTrap/AppTrap/AppTrapPreferencePane` → preference pane project (`AppTrapPreferencePane.xcodeproj`)
- `/home/runner/work/AppTrap/AppTrap/AppTrap.xcworkspace` → workspace entry point

## Dependency process (what depends on what)

### Build graph

1. `AppTrap` project builds:
   - `AppTrap.app`
   - `RelaunchObjC` helper (target dependency of `AppTrap`)
2. `AppTrapPreferencePane` project builds:
   - `AppTrap.prefPane`
   - Copies `AppTrap.app` into the preference pane bundle (`Copy AppTrap` build phase)
   - Copies bundled `Sparkle.framework` into the pane (`Copy Sparkle Framework` build phase)

### Dependency sources

- **System frameworks**: Cocoa/AppKit/Foundation/PreferencePanes/CoreServices (from macOS SDK)
- **Bundled third-party framework**: `AppTrapPreferencePane/Sparkle.framework` (vendored in repo)
- **No package manager step** is required (`brew`, `npm`, `pod`, `spm` are not used for this project)

## Setup

```bash
cd /home/runner/work/AppTrap/AppTrap
open AppTrap.xcworkspace
```

In Xcode:

1. Select scheme **AppTrap** and destination **My Mac**.
2. Build (`⌘B`).
3. Select scheme **AppTrapPreferencePane**.
4. Build again (`⌘B`).

> Build `AppTrap` first so the preference pane copy phase can package a fresh `AppTrap.app`.

## Command-line build

From `/home/runner/work/AppTrap/AppTrap`:

```bash
# 1) Build background app
xcodebuild \
  -project AppTrap/AppTrap.xcodeproj \
  -scheme AppTrap \
  -configuration Release \
  build

# 2) Build System Settings plugin (.prefPane)
xcodebuild \
  -project AppTrapPreferencePane/AppTrapPreferencePane.xcodeproj \
  -scheme AppTrap \
  -configuration Release \
  build
```

Artifacts are in Xcode DerivedData by default.

## Installation

After a successful Release build, locate `AppTrap.prefPane` in DerivedData and install it.

### UI install

- Double-click `AppTrap.prefPane`
- Choose install scope:
  - **Current user** → `~/Library/PreferencePanes/`
  - **All users** → `/Library/PreferencePanes/`

### Terminal install (current user)

```bash
mkdir -p "$HOME/Library/PreferencePanes"
cp -R "/path/to/AppTrap.prefPane" "$HOME/Library/PreferencePanes/"
```

Open **System Settings** and select **AppTrap**.

## Build and compilation verification commands

Run these on macOS with Xcode installed:

```bash
# Compile app
xcodebuild -project AppTrap/AppTrap.xcodeproj -scheme AppTrap -configuration Debug build

# Compile preference pane
xcodebuild -project AppTrapPreferencePane/AppTrapPreferencePane.xcodeproj -scheme AppTrap -configuration Debug build

# Unit tests (legacy OCUnit/XCTest targets)
xcodebuild -project AppTrap/AppTrap.xcodeproj -scheme AppTrapTests -destination 'platform=macOS' test
xcodebuild -project AppTrapPreferencePane/AppTrapPreferencePane.xcodeproj -scheme PrefPaneTests -destination 'platform=macOS' test
```

## Troubleshooting

- `xcodebuild: command not found`:
  - Install Xcode on macOS and run `xcode-select --switch /Applications/Xcode.app`.
- Signing failures in local builds:
  - The preference pane includes a `Sign Sparkle` build phase. For local unsigned builds, use `CODE_SIGNING_ALLOWED=NO` in `xcodebuild` or adjust signing settings in Xcode.

## License

```
"Do what you want to do, and go where you're going to.
Think for yourself, 'cause I won't be there with you"

You are completely free to do anything with this source code,
but if you try to make money on it you will be beaten up with a
large stick. I take no responsibility for anything, and this
license text must always be included.

— Markus Amalthea Magnuson <markus.magnuson@gmail.com>
```
