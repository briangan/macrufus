import Foundation
import Subprocess

func logURL() -> URL {
  let logFileName = "subprocess.log"
  let fileManager = FileManager.default
  let dir = URL(fileURLWithPath: fileManager.currentDirectoryPath + "/log", isDirectory: true)
  // try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  let logURL = dir.appendingPathComponent(logFileName)
  return logURL
}

// https://github.com/swiftlang/swift-subprocess
// https://swiftpackageindex.com/swiftlang/swift-subprocess#readme
func runSubprocess(cmd : String, args : Arguments, outputHandler: ((String) -> Void)?, errorHandler: ((String) -> Void)?) async throws {
  // Let's make a local log file to capture the output of the subprocess for debugging purposes.

  writeToLogFile(message: "Running subprocess: \(cmd) \(args)", at: logURL())

  if outputHandler == nil && errorHandler == nil {
    writeToLogFile(message: "No output or error handlers provided. Output will be printed to the console.", at: logURL())
    let _ = try await run(
        .name(cmd),
        arguments: args,
        input: .none,
        output: .currentStandardOutput, 
        error: .currentStandardError
    )
  }
  else {
    writeToLogFile(message: "Output and/or error handlers provided. Output will be captured by handlers.", at: logURL())
    let _ = try await run(
        .name(cmd),
        arguments: args,
        input: .none,
        output: .sequence,
        error: .sequence
    ) { execution in
        try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for try await line in execution.standardOutput.strings(bufferingPolicy: .maxLineLength(5 * 1024) ) {
                        // writeToLogFile(message: "| \(line) | hasSuffix: \(line.hasSuffix("\r"))", at: logURL())
                        outputHandler?(line)
                    }
                    /* var outputIterator = execution.standardOutput.makeAsyncIterator()
                    while let buffer = try await outputIterator.next() {
                        // Convert Buffer to String using UTF-8 encoding
                        guard let lineString = String(data: Data(buffer: buffer), encoding: .utf8) else { continue }

                        var processedLine = lineString

                        // writeToLogFile(message: "| \(processedLine) | hasSuffix: \(processedLine.hasSuffix("\r"))", at: logURL())
                        // Check if the line ends with a carriage return, indicating a progress update
                        if processedLine.hasSuffix("\r") {
                            // Remove the carriage return for logging and handling
                            processedLine.removeLast()
                            writeToLogFile(message: "Progress update: \(processedLine)", at: logURL())
                        } else {
                            writeToLogFile(message: "Output: \(processedLine)", at: logURL())
                        }
                    } */
                }
                group.addTask {
                    for try await line in execution.standardError.strings() {
                        errorHandler?(line)
                    }
                }
                try await group.waitForAll()
            } // withThrowingTaskGroup
        } // run
    }
}


// MARK: - Calling async functions from sync contexts
/*
If you call runSubprocess() from a synchronous function (one that is NOT marked 'async'), 
you must wrap the call in a Task block to execute it asynchronously.

Example of calling runSubprocess() from a hypothetical non-async function:

func someSyncFunction() {
    Task { @MainActor in // Use @MainActor if UI updates are involved
        do {
            try await runSubprocess(cmd: "ls", args: ["-la"], outputHandler: nil, errorHandler: nil)
            print("Successfully ran subprocess from sync context.")
        } catch {
            print("Error running subprocess: \(error)")
        }
    }
}
*/


/**
 * Appends a given message string to a log file at the specified URL.
 * If the file does not exist, it will be created.
 *
 * - Parameters:
 *   - message: The text message to append to the log.
 *   - logFileURL: The URL pointing to the log file.
 */
func writeToLogFile(message: String, at logFileURL: URL) {
    // 1. Prepare the content with a timestamp for better logging context
    let timestamp = DateFormatter()
    timestamp.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let formattedDate = timestamp.string(from: Date())
    let logEntry = "[\(formattedDate)] \(message)\n"

    // 2. Get the file manager instance
    let fileManager = FileManager.default

    do {
        // 3. Check if the file exists to determine if we need to append or create
        var isFileExists = false
        if fileManager.fileExists(atPath: logFileURL.path) {
            isFileExists = true
        }

        // 4. Append the content to the file
        // Using Data.append to ensure appending behavior across different OS/Swift versions
        let dataToWrite = logEntry.data(using: .utf8)!

        if isFileExists {
            // If it exists, we need to append the data. This requires opening the file handle.
            guard let fileHandle = try? FileHandle(forWritingTo: logFileURL) else {
                print("Error: Could not open file handle for writing at \(logFileURL.path)")
                return
            }
            defer {
                // Ensure the file handle is closed when done
                fileHandle.closeFile()
            }
            try fileHandle.seekToEnd() // Move to the end of the file
            try fileHandle.write(contentsOf: dataToWrite)

        } else {
            // If it doesn't exist, we create it and write the content.
            try dataToWrite.write(to: logFileURL, options: .atomic)
        }

    } catch let error as NSError {
        print("Error writing to log file at \(logFileURL.path): \(error.localizedDescription)")
    }
}

// MARK: - Example Usage

/*
// To test as individual script:
@main 
enum Script {
    static func main() async {
        let result = try await run(
          .name("ls"),
          arguments: ["-la"],
          output: .string(limit: 1 << 20)
        )
        print(result.standardOutput ?? "")
    }
}
*/

