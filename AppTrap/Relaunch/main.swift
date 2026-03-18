//
//  main.swift
//  Relaunch
//
//  Created by Kumaran Vijayan on 2015-11-11.
//  Updated for Swift 5 / modern macOS compatibility.
//

import AppKit

final class Observer: NSObject {
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
        super.init()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?)
    {
        callback()
    }
}

// main
autoreleasepool {
    let arguments = CommandLine.arguments
    guard arguments.count > 1,
          let parentPID = Int32(arguments[1]),
          let app = NSRunningApplication(processIdentifier: parentPID),
          let bundleURL = app.bundleURL
    else {
        exit(1)
    }

    // Terminate and wait for termination via KVO.
    let listener = Observer { CFRunLoopStop(CFRunLoopGetCurrent()) }
    app.addObserver(listener,
                    forKeyPath: "isTerminated",
                    options: [],
                    context: nil)
    app.terminate()
    CFRunLoopRun()
    app.removeObserver(listener, forKeyPath: "isTerminated", context: nil)

    // Relaunch using the modern NSWorkspace API.
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.addsToRecentItems = false
    configuration.activates = false
    NSWorkspace.shared.openApplication(at: bundleURL,
                                       configuration: configuration) { _, error in
        if let error = error {
            NSLog("Failed to relaunch app: %@", error as NSError)
        }
        CFRunLoopStop(CFRunLoopGetCurrent())
    }
    CFRunLoopRun() // wait for completion handler
}
