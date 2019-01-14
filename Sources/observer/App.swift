import Darwin
import Dispatch
import Files

final class App {
  private var observations: [Observation] = []

  func exit() {
    observations.forEach { $0.cancel() }
    observations.removeAll()

    DispatchQueue.main.async {
      Darwin.exit(0)
    }
  }

  func run() -> Never {
    dispatchMain()
  }

  func startObserving(_ paths: [Path]) throws {
    var paths = paths

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
  }
}
