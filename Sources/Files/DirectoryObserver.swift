import Dispatch

public final class DirectoryObserver {
  private let contents: Box<Set<String>>
  private var isCancelled = false
  private let queue: DispatchQueue
  private let source: DispatchSourceFileSystemObject

  public init(directory: Directory, target: DispatchQueue, changeHandler: @escaping (Event) -> Void) {
    self.contents = Box(directory.contents)
    self.queue = DispatchQueue(label: "DirectoryObserver:\(directory.file.path)", target: target)
    self.source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: directory.file.descriptor,
      eventMask: [.delete, .rename, .write],
      queue: self.queue
    )

    self.source.setEventHandler { [unowned self] in
      // FIXME: event is a mask, not an enum: may contain multiple events
      switch self.source.data {
      case .delete, .rename:
        changeHandler(.deleted)

      case .write:
        let newContents = directory.contents
        let changeset = Changeset(currentContents: self.contents.value, newContents: newContents)
        self.contents.value = newContents

        if let changeset = changeset {
          changeHandler(.contentsChanged(changeset))
        }

      case let event:
        preconditionFailure("unexpected directory event: \(event)")
      }
    }

    self.source.setCancelHandler { [contents, path = directory.path] in
      let contents = contents.value.map { path + $0 }
      changeHandler(.cancelled(previousContents: contents))
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

  public enum Event {
    case cancelled(previousContents: [Path])
    case contentsChanged(Changeset)
    case deleted
  }
}

private extension Directory {
  var contents: Set<String> {
    var contents = Set<String>()
    enumerateEntries { contents.insert($0.basename) }
    return contents
  }
}
