/*
 Settings/SettingsManager.swift
 Overview

 Created by William Pierce on 1/12/25.

 Manages centralized settings operations and reset functionality across the application.
*/

import SwiftUI

@MainActor
final class SettingsManager: ObservableObject {
    // MARK: - Dependencies
    private let hotkeyStorage: HotkeyStorage
    private let logger = AppLogger.settings

    // MARK: - Published State
    @Published var filterAppNames: [String] {
        didSet {
            UserDefaults.standard.set(filterAppNames, forKey: FilterSettingsKeys.appNames)
        }
    }

    init(hotkeyStorage: HotkeyStorage) {
        self.hotkeyStorage = hotkeyStorage

        // Initialize filter app names from UserDefaults
        if let storedNames = UserDefaults.standard.array(forKey: FilterSettingsKeys.appNames)
            as? [String]
        {
            self.filterAppNames = storedNames
        } else {
            self.filterAppNames = FilterSettingsKeys.defaults.appNames
        }
    }

    // MARK: - Settings Reset

    func resetAllSettings() {
        logger.info("Initiating settings reset")

        // Reset Window settings
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.previewOpacity,
            forKey: WindowSettingsKeys.previewOpacity)
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.defaultWidth,
            forKey: WindowSettingsKeys.defaultWidth)
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.defaultHeight,
            forKey: WindowSettingsKeys.defaultHeight)
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.managedByMissionControl,
            forKey: WindowSettingsKeys.managedByMissionControl)
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.shadowEnabled,
            forKey: WindowSettingsKeys.shadowEnabled)
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.createOnLaunch,
            forKey: WindowSettingsKeys.createOnLaunch)
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.alignmentEnabled,
            forKey: WindowSettingsKeys.alignmentEnabled)
        UserDefaults.standard.set(
            WindowSettingsKeys.defaults.closeOnCaptureStop,
            forKey: WindowSettingsKeys.closeOnCaptureStop)

        // Reset Overlay settings
        UserDefaults.standard.set(
            OverlaySettingsKeys.defaults.focusBorderEnabled,
            forKey: OverlaySettingsKeys.focusBorderEnabled)
        UserDefaults.standard.set(
            OverlaySettingsKeys.defaults.focusBorderWidth,
            forKey: OverlaySettingsKeys.focusBorderWidth)
        UserDefaults.standard.set(
            OverlaySettingsKeys.defaults.focusBorderColor.rawValue,
            forKey: OverlaySettingsKeys.focusBorderColor)
        UserDefaults.standard.set(
            OverlaySettingsKeys.defaults.sourceTitleEnabled,
            forKey: OverlaySettingsKeys.sourceTitleEnabled)
        UserDefaults.standard.set(
            OverlaySettingsKeys.defaults.sourceTitleFontSize,
            forKey: OverlaySettingsKeys.sourceTitleFontSize)
        UserDefaults.standard.set(
            OverlaySettingsKeys.defaults.sourceTitleBackgroundOpacity,
            forKey: OverlaySettingsKeys.sourceTitleBackgroundOpacity)

        // Reset Preview settings
        UserDefaults.standard.set(
            PreviewSettingsKeys.defaults.hideInactiveApplications,
            forKey: PreviewSettingsKeys.hideInactiveApplications)
        UserDefaults.standard.set(
            PreviewSettingsKeys.defaults.hideActiveWindow,
            forKey: PreviewSettingsKeys.hideActiveWindow)
        UserDefaults.standard.set(
            PreviewSettingsKeys.defaults.captureFrameRate,
            forKey: PreviewSettingsKeys.captureFrameRate)

        // Reset Filter settings
        filterAppNames = FilterSettingsKeys.defaults.appNames
        UserDefaults.standard.set(
            FilterSettingsKeys.defaults.isBlocklist,
            forKey: FilterSettingsKeys.isBlocklist)

        // Reset Hotkey settings through HotkeyStorage
        hotkeyStorage.resetToDefaults()

        logger.info("Settings reset completed successfully")
    }
}
