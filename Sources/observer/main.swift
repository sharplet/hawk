import Dispatch
import Files
import Foundation

func initialize() throws {
  var paths = CommandLine.arguments.dropFirst().map(Path.init)
  var sources: [DispatchSourceFileSystemObject] = []

  while !paths.isEmpty {
    let path = paths.removeFirst()
    let file = try File(path)

    if file.isDirectory {
      File.forEachEntry(inDirectory: path) { entry in
        guard !entry.hasPrefix(".") else { return }
        paths.append(path + entry)
      }
    }

    let source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: file.descriptor,
      eventMask: [.attrib, .delete, .rename, .write],
      queue: .main
    )

    sources.append(source)

    source.setCancelHandler {
      _ = file
    }

    var count = 0

    source.setEventHandler {
      let event: String

      switch source.data {
      case .attrib:
        event = "attrib"
      case .delete:
        event = "delete"
      case .rename:
        event = "rename"
      case .write:
        event = "write"
      default:
        return
      }

      count += 1

      print("\(event): \(path) (\(count))")
    }

    source.resume()
  }
}

do {
  try initialize()
  dispatchMain()
} catch {
  var message = error.localizedDescription
  if let failureReason = (error as NSError).localizedFailureReason {
    message += ": \(failureReason)"
  }
  fputs("fatal: \(message)\n", stderr)
  exit(1)
}
