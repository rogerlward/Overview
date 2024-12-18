/*
 SelectionView.swift
 Overview

 Created by William Pierce on 9/15/24.

 Manages window selection and capture initialization, providing the initial setup
 interface for Overview preview windows and handling permission flows.
*/

import ScreenCaptureKit
import SwiftUI

struct SelectionView: View {
    @ObservedObject var previewManager: PreviewManager
    @ObservedObject var appSettings: AppSettings
    @Binding var captureManagerId: UUID?
    @Binding var showingSelection: Bool
    @Binding var selectedWindowSize: CGSize?

    @State private var selectedWindow: SCWindow?
    @State private var isInitializing = true
    @State private var initializationError = ""
    @State private var windowListRefreshToken = UUID()

    var body: some View {
        VStack {
            if isInitializing {
                ProgressView("Loading windows...")
            } else if let error = initializationError.isEmpty ? nil : initializationError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if let captureManager = activeCaptureManager {
                selectionInterface(captureManager)
            }
        }
        .task {
            await initializeCaptureSystem()
        }
    }

    private var activeCaptureManager: CaptureManager? {
        guard let id = captureManagerId else {
            AppLogger.interface.warning("No capture manager ID available")
            return nil
        }
        return previewManager.captureManagers[id]
    }

    private func selectionInterface(_ captureManager: CaptureManager) -> some View {
        VStack {
            HStack {
                windowSelectionPicker(captureManager)
                refreshButton(captureManager)
            }
            .padding()

            startPreviewButton(captureManager)
        }
    }

    private func windowSelectionPicker(_ captureManager: CaptureManager) -> some View {
        Picker("", selection: $selectedWindow) {
            Text("Select a window").tag(nil as SCWindow?)
            ForEach(captureManager.availableWindows, id: \.windowID) { window in
                Text(window.title ?? "Untitled").tag(window as SCWindow?)
            }
        }
        .id(windowListRefreshToken)
        .onChange(of: selectedWindow) { oldValue, newValue in
            if let window = newValue {
                AppLogger.interface.info("Window selected: '\(window.title ?? "Untitled")'")
            }
        }
    }

    private func refreshButton(_ captureManager: CaptureManager) -> some View {
        Button(action: { Task { await refreshAvailableWindows(captureManager) } }) {
            Image(systemName: "arrow.clockwise")
        }
    }

    private func startPreviewButton(_ captureManager: CaptureManager) -> some View {
        Button("Start Preview") {
            initiateWindowPreview(captureManager)
        }
        .disabled(selectedWindow == nil)
    }

    private func initializeCaptureSystem() async {
        guard let captureManager = activeCaptureManager else {
            AppLogger.interface.error("Setup failed: No valid capture manager")
            initializationError = "Setup failed"
            isInitializing = false
            return
        }

        do {
            AppLogger.interface.debug("Requesting screen recording permission")
            try await captureManager.requestPermission()
            await captureManager.updateAvailableWindows()

            AppLogger.interface.info("Capture setup completed successfully")
            isInitializing = false
        } catch {
            AppLogger.interface.logError(
                error,
                context: "Screen recording permission request")
            initializationError = "Permission denied"
            isInitializing = false
        }
    }

    private func refreshAvailableWindows(_ captureManager: CaptureManager) async {
        AppLogger.interface.debug("Refreshing window list")
        await captureManager.updateAvailableWindows()
        await MainActor.run {
            windowListRefreshToken = UUID()
            AppLogger.interface.info(
                "Window list refreshed, count: \(captureManager.availableWindows.count)")
        }
    }

    @MainActor
    private func initiateWindowPreview(_ captureManager: CaptureManager) {
        guard let window = selectedWindow else {
            AppLogger.interface.warning("Attempted to start preview without window selection")
            return
        }

        AppLogger.interface.debug("Starting preview for window: '\(window.title ?? "Untitled")'")

        captureManager.selectedWindow = window
        selectedWindowSize = CGSize(width: window.frame.width, height: window.frame.height)
        showingSelection = false

        Task {
            do {
                try await captureManager.startCapture()
                AppLogger.interface.info("Preview started successfully")
            } catch {
                AppLogger.interface.logError(
                    error,
                    context: "Starting window preview")
            }
        }
    }
}
