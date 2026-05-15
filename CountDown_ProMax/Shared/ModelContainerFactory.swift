import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: "CountDown_ProMax", category: "ModelContainer")

struct ModelContainerFactory {
    /// Result of creating a ModelContainer, including whether CloudKit is active.
    struct Result {
        let container: ModelContainer
        let isCloudKitEnabled: Bool
    }

    /// Creates the main app's ModelContainer with CloudKit sync and App Group storage.
    /// Falls back to CloudKit without App Group if the group container fails.
    static func create() throws -> Result {
        let schema = Schema([Countdown.self])

        // First try: CloudKit + App Group (enables widget data sharing)
        do {
            let config = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(AppConstants.appGroupID),
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(for: schema, configurations: config)
            logger.info("ModelContainer: CloudKit + App Group ✅")
            return Result(container: container, isCloudKitEnabled: true)
        } catch {
            logger.warning("App Group + CloudKit failed: \(error)")
            // Try deleting stale DB files and retry once
            removeStaleDatabase(groupID: AppConstants.appGroupID)
        }

        // Retry after cleanup
        do {
            let config = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(AppConstants.appGroupID),
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(for: schema, configurations: config)
            logger.info("ModelContainer: CloudKit + App Group (after cleanup) ✅")
            return Result(container: container, isCloudKitEnabled: true)
        } catch {
            logger.warning("Retry also failed: \(error). Trying App Group without CloudKit...")
        }

        // Try: App Group without CloudKit (local only, but widgets can still access)
        do {
            let config = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(AppConstants.appGroupID),
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: config)
            logger.info("ModelContainer: App Group, no CloudKit (local only) ✅")
            return Result(container: container, isCloudKitEnabled: false)
        } catch {
            logger.warning("App Group without CloudKit also failed: \(error). Trying plain CloudKit...")
        }

        // Try: CloudKit without App Group
        do {
            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .automatic
            )
            let container = try ModelContainer(for: schema, configurations: config)
            logger.info("ModelContainer: CloudKit, no App Group ✅")
            return Result(container: container, isCloudKitEnabled: true)
        } catch {
            logger.error("All CloudKit attempts failed: \(error)")
            throw error
        }
    }

    /// Removes stale SwiftData/CoreData database files from the App Group container.
    private static func removeStaleDatabase(groupID: String) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            logger.warning("Could not locate App Group container directory")
            return
        }

        let dbName = "CountDown_ProMax"
        let extensions = ["store", "store-shm", "store-wal"]
        let fm = FileManager.default

        // SwiftData puts the store in Library/Application Support/
        let supportDir = containerURL.appendingPathComponent("Library/Application Support")

        for ext in extensions {
            let fileURL = supportDir.appendingPathComponent("\(dbName).\(ext)")
            if fm.fileExists(atPath: fileURL.path) {
                do {
                    try fm.removeItem(at: fileURL)
                    logger.info("Removed stale file: \(fileURL.lastPathComponent)")
                } catch {
                    logger.warning("Failed to remove \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        // Also check for default.store variant
        for ext in extensions {
            let fileURL = supportDir.appendingPathComponent("default.\(ext)")
            if fm.fileExists(atPath: fileURL.path) {
                do {
                    try fm.removeItem(at: fileURL)
                    logger.info("Removed stale file: \(fileURL.lastPathComponent)")
                } catch {
                    logger.warning("Failed to remove \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    /// Creates a read-only ModelContainer for the widget extension.
    /// Uses the same App Group store but no CloudKit (only the main app syncs).
    static func createForWidget() throws -> ModelContainer {
        let schema = Schema([Countdown.self])
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppConstants.appGroupID),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}
