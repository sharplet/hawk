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
      var count = 0

      let observer = FileObserver(file: file, target: .main) { event in
        let description: String

        switch event {
        case .attrib:
          description = "attrib"
        case .delete:
          description = "delete"
        case .rename:
          description = "rename"
        case .write:
          description = "write"
        default:
          return
        }

        count += 1

        print("\(description): \(path) (\(count))")
      }
      newObservation = Observation(observer: observer)
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
