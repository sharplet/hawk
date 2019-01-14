import Dispatch

public final class DirectoryObserver {
  private var contents: Set<String>
  private var isCancelled = false
  private let queue: DispatchQueue
  private let source: DispatchSourceFileSystemObject

  public init(directory: Directory, target: DispatchQueue, changeHandler: @escaping (Changeset) -> Void) {
    self.contents = directory.contents
    self.queue = DispatchQueue(label: "DirectoryObserver:\(directory.file.path)", target: target)
    self.source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: directory.file.descriptor,
      eventMask: .write,
      queue: self.queue
    )

    self.source.setEventHandler { [unowned self] in
      let newContents = directory.contents
      let changeset = Changeset(currentContents: self.contents, newContents: newContents)
      self.contents = newContents

      if let changeset = changeset {
        changeHandler(changeset)
      }
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

extension DirectoryObserver {
  public struct Changeset {
    public let deletedEntries: Set<String>
    public let newEntries: Set<String>

    fileprivate init?(currentContents: Set<String>, newContents: Set<String>) {
      self.deletedEntries = currentContents.subtracting(newContents)
      self.newEntries = newContents.subtracting(currentContents)
      guard !deletedEntries.isEmpty || !newEntries.isEmpty else { return nil }
    }
  }
}

private extension Directory {
  var contents: Set<String> {
    var contents = Set<String>()
    enumerateEntries { contents.insert($0.basename) }
    return contents
  }
}
