/*
 Source/SourceManager.swift
 Overview

 Created by William Pierce on 12/10/24.

 Coordinates source window management operations including focus handling,
 filtering, and state observation across the application.
*/

import ScreenCaptureKit
import SwiftUI

@MainActor
final class SourceManager: ObservableObject {
    // MARK: - Published State
    @Published private(set) var focusedBundleId: String?
    @Published private(set) var focusedProcessId: pid_t?
    @Published private(set) var isOverviewActive: Bool = true
    @Published private(set) var sourceTitles: [SourceID: String] = [:]

    // MARK: - Dependencies
    private let appSettings: AppSettings
    private let sourceServices: SourceServices = SourceServices.shared
    private let captureServices: CaptureServices = CaptureServices.shared
    private let logger = AppLogger.sources
    private let observerId = UUID()

    // MARK: - Types

    struct SourceID: Hashable {
        let processID: pid_t
        let windowID: CGWindowID
    }

    // MARK: - Initialization

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        logger.debug("Initializing source window manager")
        setupObservers()
        logger.info("Source window manager initialization complete")
    }

    // MARK: - Public Interface

    func focusSource(_ source: SCWindow) {
        logger.debug("Processing source window focus request: '\(source.title ?? "untitled")'")
        sourceServices.sourceFocus.focusSource(source: source)
    }

    func focusSource(withTitle title: String) -> Bool {
        logger.debug("Processing title-based focus request: '\(title)'")
        let success = sourceServices.sourceFocus.focusSource(withTitle: title)

        if !success {
            logger.error("Failed to focus source window: '\(title)'")
        }

        return success
    }

    func getFilteredSources() async throws -> [SCWindow] {
        logger.debug("Retrieving filtered window list")

        let availableSources = try await captureServices.getAvailableSources()
        let filteredSources = sourceServices.sourceFilter.filterSources(
            availableSources,
            appFilterNames: appSettings.appFilterNames,
            isFilterBlocklist: appSettings.isFilterBlocklist
        )

        logger.info("Retrieved \(filteredSources.count) filtered source window")
        return filteredSources
    }

    // MARK: - Private Methods

    private func setupObservers() {
        logger.debug("Configuring window state observers")

        sourceServices.sourceObserver.addObserver(
            id: observerId,
            onFocusChanged: { [weak self] in await self?.updateFocusedSource() },
            onTitleChanged: { [weak self] in await self?.updateSourceTitles() }
        )

        logger.info("Window observers configured successfully")
    }

    private func updateFocusedSource() async {
        guard let activeApp: NSRunningApplication = NSWorkspace.shared.frontmostApplication else {
            logger.debug("No active application found")
            return
        }

        focusedProcessId = activeApp.processIdentifier
        focusedBundleId = activeApp.bundleIdentifier
        isOverviewActive = activeApp.bundleIdentifier == Bundle.main.bundleIdentifier

        logger.debug("Focus state updated: bundleId=\(activeApp.bundleIdentifier ?? "unknown")")
    }

    private func updateSourceTitles() async {
        do {
            let sources = try await captureServices.getAvailableSources()
            sourceTitles = Dictionary(
                uniqueKeysWithValues: sources.compactMap { source in
                    guard let processID = source.owningApplication?.processID,
                        let title = source.title
                    else { return nil }
                    return (SourceID(processID: processID, windowID: source.windowID), title)
                }
            )
            logger.debug("Source window titles updated: count=\(sourceTitles.count)")
        } catch {
            logger.logError(error, context: "Failed to update source window titles")
        }
    }
}
