import Darwin
import Dispatch
import Files

final class App {
  private let errorHandler: (App, Error) -> Void
  private var observations: [Path: Observation] = [:]

  init(errorHandler: @escaping (App, Error) -> Void) {
    self.errorHandler = errorHandler
  }

  func exit(failure: Bool = false) {
    observations.forEach { $1.cancel() }
    observations.removeAll()

    DispatchQueue.main.async {
      Darwin.exit(failure ? 1 : 0)
    }
  }

  func run() -> Never {
    dispatchMain()
  }

  func startObserving(_ paths: [Path]) {
    do {
      try _startObserving(paths)
    } catch {
      errorHandler(self, error)
    }
  }

  private func _startObserving(_ paths: [Path]) throws {
    var paths = paths

    while !paths.isEmpty {
      let path = paths.removeFirst()
      let file = try File(path)
      let newObservation: Observation

      if let directory = Directory(file) {
        let observer = DirectoryObserver(directory: directory, target: .main) { [unowned self] in
          self.handleDirectoryChange($0, at: path)
        }
        newObservation = Observation(observer: observer)

        directory.enumerateEntries {
          paths.append($0)
        }
      } else {
        var count = 0
        let observer = FileObserver(file: file, target: .main) { event in
          count += 1
          print("\(event): \(path) (\(count))")
        }
        newObservation = Observation(observer: observer)
      }

      observations[path] = newObservation

      print("added: \(path)", terminator: "")
      if File.isDirectory(path) {
        print("/")
      } else {
        print()
      }
    }
  }

  private func handleDirectoryChange(_ changeset: DirectoryObserver.Changeset, at path: Path) {
    for deleted in changeset.deletedEntries {
      let path = path + deleted
      observations[path]?.cancel()
      observations[path] = nil
    }

    let added = changeset.newEntries.map { path + $0 }
    startObserving(added)
  }
}
