import Dispatch
import Files

struct Observation {
  let cancel: () -> Void
}

extension Observation {
  init(observer: DirectoryObserver) {
    self.cancel = observer.cancel
  }

  init(observer: FileObserver) {
    self.cancel = observer.cancel
  }
}
