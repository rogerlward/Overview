/*
 Settings/Views/SourceSettingsTab.swift
 Overview

 Created by William Pierce on 1/12/25.
*/

import SwiftUI

struct SourceSettingsTab: View {
    // MARK: - App Filter Settings
    @AppStorage(SourceSettingsKeys.isBlocklist)
    private var isBlocklist = SourceSettingsKeys.defaults.isBlocklist
    
    // MARK: - Dependencies
    @ObservedObject var settingsManager: SettingsManager
    private let logger = AppLogger.settings

    // MARK: - State
    @State private var newAppName = ""

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Source App Filter")
                        .font(.headline)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 4)

                VStack {
                    if settingsManager.filterAppNames.isEmpty {
                        List {
                            Text("No applications filtered")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        List(settingsManager.filterAppNames, id: \.self) { appName in
                            HStack {
                                Text(appName)
                                Spacer()
                                Button(action: { removeAppFilter(appName) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Picker("Filter Mode", selection: $isBlocklist) {
                    Text("Blocklist").tag(true)
                    Text("Allowlist").tag(false)
                }
                .pickerStyle(.segmented)

                HStack {
                    TextField("App Name", text: $newAppName)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                    Button("Add") {
                        addAppFilter()
                    }
                    .disabled(newAppName.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func addAppFilter() {
        guard !newAppName.isEmpty else { return }
        logger.info("Adding app filter: '\(newAppName)'")
        settingsManager.filterAppNames.append(newAppName)
        newAppName = ""
    }

    private func removeAppFilter(_ appName: String) {
        if let index = settingsManager.filterAppNames.firstIndex(of: appName) {
            settingsManager.filterAppNames.remove(at: index)
            logger.info("Removed app filter: '\(appName)'")
        }
    }
}
