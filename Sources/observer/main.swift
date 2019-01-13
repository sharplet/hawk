import Dispatch
import Files
import Foundation

func startObserving(_ paths: [Path]) throws -> [Observation] {
  var paths = paths
  var observations: [Observation] = []

  while !paths.isEmpty {
    let path = paths.removeFirst()
    let file = try File(path)
    let newObservation: Observation

    if let directory = Directory(file) {
      let observer = DirectoryObserver(directory: directory, target: .main) {
        print($0)
      }
      newObservation = Observation(observer: observer)

      directory.enumerateEntries {
        paths.append($0)
      }
    } else {
      let source = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: file.descriptor,
        eventMask: [.attrib, .delete, .rename, .write],
        queue: .main
      )
      newObservation = Observation(dispatchSource: source)

      source.setCancelHandler {
        _ = file
      }

      var count = 0

      source.setEventHandler { [unowned source] in
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

    observations.append(newObservation)

    print(path, terminator: "")
    if File.isDirectory(path) {
      print("/")
    } else {
      print()
    }
  }

  return observations
}

@discardableResult
func handleInterrupt(execute body: @escaping () -> Void) -> DispatchSourceSignal {
  signal(SIGINT, SIG_IGN)
  let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
  source.setEventHandler(handler: body)
  source.setCancelHandler { _ = source }
  source.resume()
  return source
}

do {
  let paths = CommandLine.arguments.dropFirst().map(Path.init)
  var observations = try startObserving(paths)
  handleInterrupt {
    observations.forEach { $0.cancel() }
    observations.removeAll()
    DispatchQueue.main.async {
      exit(0)
    }
  }
  dispatchMain()
} catch {
  var message = error.localizedDescription
  if let failureReason = (error as NSError).localizedFailureReason {
    message += ": \(failureReason)"
  }
  fputs("fatal: \(message)\n", stderr)
  exit(1)
}
