import Dispatch
import Files

struct Observation {
  let cancel: () -> Void
}

extension Observation {
  init(dispatchSource: DispatchSourceProtocol) {
    self.cancel = dispatchSource.cancel
  }

  init(observer: DirectoryObserver) {
    self.cancel = observer.cancel
  }
}
