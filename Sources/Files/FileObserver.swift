import Dispatch

public final class FileObserver {
  private let queue: DispatchQueue
  private let source: DispatchSourceFileSystemObject

  public init(file: File, target: DispatchQueue, changeHandler: @escaping (DispatchSource.FileSystemEvent) -> Void) {
    self.queue = DispatchQueue(label: "FileObserver:\(file.path)", target: target)
    self.source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: file.descriptor,
      eventMask: [.attrib, .delete, .rename, .write],
      queue: self.queue
    )

    self.source.setEventHandler { [unowned self] in
      let event = self.source.data
      changeHandler(event)
    }

    self.source.setCancelHandler {
      _ = file
    }

    self.source.resume()
  }

  public func cancel() {
    source.cancel()
  }
}
