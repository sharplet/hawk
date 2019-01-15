import Dispatch
import Files

protocol Observation {
  func cancel()
}

extension DirectoryObserver: Observation {}
extension FileObserver: Observation {}
