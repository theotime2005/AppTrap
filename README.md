# AppTrap

AppTrap is a macOS utility that automatically offers to move associated files (preferences, caches, application support data) to the Trash when you delete an application.

## Requirements

- **macOS 13 (Ventura) or later** — this is the minimum supported version.
- **Xcode 15 or later** — required to build the project. Download it from the Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/).

## Architecture

The project is split into two parts:

| Component | Description |
|-----------|-------------|
| `AppTrap` | Background agent (`AppTrap.app`) that watches the Trash and detects removed apps |
| `AppTrapPreferencePane` | System Settings preference pane (`AppTrap.prefPane`) that lets the user start/stop the agent and manage login items |

The preference pane embeds `AppTrap.app` inside its bundle so both components are distributed together.

## Building from source

### Using Xcode (recommended)

1. Open the workspace:
   ```
   open AppTrap.xcworkspace
   ```
2. In the Xcode toolbar, select the **AppTrap** scheme and choose **My Mac** as the destination.
3. Press **⌘B** (or choose **Product › Build**) to compile the AppTrap background agent.
4. Switch the scheme to **AppTrapPreferencePane** and press **⌘B** again to compile the preference pane.

> **Tip:** Build **AppTrap** first. The preference pane build phase automatically copies the freshly built `AppTrap.app` into its bundle.

### Using `xcodebuild` (command line)

```bash
# 1. Build the background agent
xcodebuild -project AppTrap/AppTrap.xcodeproj \
           -scheme AppTrap \
           -configuration Release \
           build

# 2. Build the preference pane (embeds AppTrap.app automatically)
xcodebuild -project AppTrapPreferencePane/AppTrapPreferencePane.xcodeproj \
           -scheme AppTrapPreferencePane \
           -configuration Release \
           build
```

Built products are placed in `~/Library/Developer/Xcode/DerivedData/` by default.

## Installation

1. Build both components (see above).
2. Locate `AppTrapPreferencePane.prefPane` in the build output (DerivedData).
3. Double-click the `.prefPane` file to install it. macOS will prompt you to install it for just your user account or for all users.
4. Open **System Settings › AppTrap** to enable the agent and configure the "Start on login" option.

## Running the tests

Select the **AppTrapTests** or **PrefPaneTests** scheme in Xcode and press **⌘U**, or use `xcodebuild test`:

```bash
xcodebuild -project AppTrap/AppTrap.xcodeproj \
           -scheme AppTrapTests \
           -destination 'platform=macOS' \
           test
```

## What changed for modern macOS compatibility

The following deprecated or removed APIs were replaced when updating the project to support macOS 13+:

| Old API | Replacement | Reason |
|---------|-------------|--------|
| `NSWorkspace -performFileOperation:NSWorkspaceRecycleOperation` | `NSFileManager -trashItemAtURL:resultingItemURL:error:` | Removed in macOS 12 |
| `NSTask.launchPath` / `-launch` | `NSTask.executableURL` / `-launchAndReturnError:` | Deprecated in macOS 10.13 |
| `NSWorkspace -launchApplicationAtURL:options:configuration:error:` | `NSWorkspace -openApplicationAtURL:configuration:completionHandler:` | Deprecated in macOS 10.15, removed in macOS 15 |
| `NSWorkspace -openURLs:withAppBundleIdentifier:options:additionalEventParamDescriptor:launchIdentifiers:` | `NSWorkspace -openApplicationAtURL:configuration:completionHandler:` | Deprecated in macOS 10.15, removed in macOS 15 |
| `LSSharedFileList*` (login items) | `SMAppService -loginItemServiceWithIdentifier:` | Removed in macOS 13 |
| `NSBeginAlertSheet` | `NSAlert -beginSheetModalForWindow:completionHandler:` | Deprecated in macOS 10.9 |
| `NSOnState` / `NSOffState` / `NSAlertDefaultReturn` | `NSControlStateValueOn/Off` / `NSAlertFirstButtonReturn` | Deprecated in macOS 10.13–14 |
| `NSColor.blackColor` / `grayColor` | `NSColor.labelColor` / `secondaryLabelColor` | Adapts automatically to Dark Mode |
| Swift 1.x/2.x syntax in `Relaunch/main.swift` | Swift 5 | Required for modern toolchains |

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
