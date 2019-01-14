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
        let observer = DirectoryObserver(directory: directory, target: .main) { [unowned self] event in
          switch event {
          case let .contentsChanged(changeset):
            self.handleDirectoryChange(changeset, at: path)
          case .deleted:
            self.removeObservation(at: path)
          }
        }
        newObservation = Observation(observer: observer)

        directory.enumerateEntries {
          paths.append($0)
        }
      } else {
        let observer = FileObserver(file: file, target: .main) { [unowned self] event in
          switch event {
          case .changed:
            print("file changed: \(path)")
          case .deleted:
            self.removeObservation(at: path)
          }
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
      removeObservation(at: path + deleted)
    }

    let added = changeset.newEntries.map { path + $0 }
    startObserving(added)
  }

  private func removeObservation(at path: Path) {
    if let observation = observations.removeValue(forKey: path) {
      observation.cancel()
      print("removed: \(path)")
    }
  }
}
