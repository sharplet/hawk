import Dispatch

public final class FileObserver {
  private var isCancelled = false
  private let queue: DispatchQueue
  private let source: DispatchSourceFileSystemObject

  public init(file: File, target: DispatchQueue, changeHandler: @escaping (Event) -> Void) {
    self.queue = DispatchQueue(label: "FileObserver:\(file.path)", target: target)
    self.source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: file.descriptor,
      eventMask: [.attrib, .delete, .rename, .write],
      queue: self.queue
    )

    self.source.setEventHandler { [unowned self] in
      switch self.source.data {
      case .attrib, .write:
        changeHandler(.changed)
      case .delete, .rename:
        changeHandler(.deleted)
      case let event:
        preconditionFailure("unexpected file event: \(event)")
      }
    }

    self.source.setCancelHandler {
      _ = file
    }

    self.source.resume()
  }

  public func cancel() {
    guard !isCancelled else { return }
    isCancelled = true
    source.cancel()
  }

  deinit {
    cancel()
  }
}

extension FileObserver {
  public enum Event {
    case changed
    case deleted
  }
}
