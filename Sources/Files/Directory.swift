import Darwin

public struct Directory {
  let file: File

  public init?(_ file: File) {
    guard file.isDirectory else { return nil }
    self.file = file
  }

  public var path: Path {
    return file.path
  }

  public func enumerateEntries(_ body: (Path) throws -> Void) rethrows {
    try File.forEachEntry(inDirectory: file.path) { entry in
      guard !entry.hasPrefix(".") else { return }
      try body(file.path + entry)
    }
  }
}

private extension File {
  private static let nameOffset = MemoryLayout.offset(of: \dirent.d_name)!

  static func forEachEntry(inDirectory path: Path, _ body: (String) throws -> Void) rethrows {
    guard let dir = opendir(path._path) else { return }
    defer { closedir(dir) }

    while let entry = readdir(dir) {
      let length = entry.load(\.d_namlen)!

      let name = UnsafeRawPointer(entry)
        .advanced(by: nameOffset)
        .assumingMemoryBound(to: UInt8.self)

      let codeUnits = UnsafeBufferPointer(start: name, count: Int(length))
      let string = String(decoding: codeUnits, as: UTF8.self)
      try body(string)
    }
  }
}
