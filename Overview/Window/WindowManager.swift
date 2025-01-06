/*
 Window/WindowManager.swift
 Overview

 Created by William Pierce on 1/5/25.

 Manages the creation, configuration, and lifecycle of preview windows,
 coordinating window state persistence and restoration.
*/

import SwiftUI

final class WindowManager {
    // MARK: - Dependencies
    private let settings: AppSettings
    private let previewManager: PreviewManager
    private let sourceManager: SourceManager
    private let windowStorage: WindowStorage = WindowStorage.shared
    private let logger = AppLogger.interface

    // MARK: - Private State
    private var activeWindows: Set<NSWindow> = []
    private var windowDelegates: [NSWindow: WindowDelegate] = [:]
    private var sessionWindowCounter: Int
    
    // MARK: - Constants
    private let cascadeOffsetMultiplier: CGFloat = 25

    init(settings: AppSettings, preview: PreviewManager, source: SourceManager) {
        self.settings = settings
        self.previewManager = preview
        self.sourceManager = source
        self.sessionWindowCounter = 0
        logger.debug("Window service initialized")
    }

    deinit {
        windowDelegates.removeAll()
        activeWindows.removeAll()
        logger.debug("Window service resources cleaned up")
    }

    // MARK: - Window Management

    func createPreviewWindow(at frame: NSRect? = nil) {
        let windowFrame = frame ?? createDefaultFrame()
        let window = createConfiguredWindow(with: windowFrame)
        setupWindowDelegate(for: window)
        setupWindowContent(window)
        
        activeWindows.insert(window)
        sessionWindowCounter += 1

        window.orderFront(nil)
        logger.info("Created new preview window")
    }

    // MARK: - State Management

    func saveWindowStates() {
        windowStorage.saveWindowStates()
    }

    func restoreWindowStates() {
        windowStorage.restoreWindows { [weak self] frame in
            self?.createPreviewWindow(at: frame)
        }
    }

    // MARK: - Private Methods

    private func createDefaultFrame() -> NSRect {
        guard let screenFrame = NSScreen.main?.frame else {
            logger.warning("Unable to retrieve main screen frame, defaulting to zero")
            return .zero
        }
        
        let centerX = (screenFrame.width - settings.previewDefaultWidth) / 2
        let centerY = (screenFrame.height - settings.previewDefaultHeight) / 2
        
        let xOffset = CGFloat(sessionWindowCounter) * cascadeOffsetMultiplier
        let yOffset = CGFloat(sessionWindowCounter) * cascadeOffsetMultiplier
        
        return NSRect(
            x: centerX + xOffset,
            y: centerY - yOffset,
            width: settings.previewDefaultWidth,
            height: settings.previewDefaultHeight
        )
    }

    private func createConfiguredWindow(with frame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.level = .statusBar + 1
        
        return window
    }

    private func setupWindowDelegate(for window: NSWindow) {
        let delegate = WindowDelegate(windowManager: self)
        windowDelegates[window] = delegate
        window.delegate = delegate
    }

    private func setupWindowContent(_ window: NSWindow) {
        let contentView = ContentView(
            appSettings: settings,
            previewManager: previewManager,
            sourceManager: sourceManager
        )
        window.contentView = NSHostingView(rootView: contentView)
    }
}

// MARK: - Window Delegate

private final class WindowDelegate: NSObject, NSWindowDelegate {
    private weak var windowManager: WindowManager?

    init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }
}
