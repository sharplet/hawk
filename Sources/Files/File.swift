import Clibc
import Darwin

public final class File {
  public let descriptor: Int32
  public let path: Path

  public init?(_ path: Path) {
    self.descriptor = open(path._path, 0)
    guard self.descriptor >= 0 else { return nil }
    self.path = path
  }

  public var isDirectory: Bool {
    return File.isDirectory(path)
  }

  deinit {
    close(descriptor)
  }
}

extension File {
  private static let nameOffset = MemoryLayout.offset(of: \dirent.d_name)!

  public static func forEachEntry(inDirectory path: Path, _ body: (String) -> Void) {
    guard let dir = opendir(path._path) else { return }
    defer { closedir(dir) }

    while let entry = readdir(dir) {
      let length = entry.load(\.d_namlen)!

      let name = UnsafeRawPointer(entry)
        .advanced(by: nameOffset)
        .assumingMemoryBound(to: UInt8.self)

      let codeUnits = UnsafeBufferPointer(start: name, count: Int(length))
      let string = String(decoding: codeUnits, as: UTF8.self)
      body(string)
    }
  }

  public static func isDirectory(_ path: Path) -> Bool {
    return observer_is_dir(path._path) == 1
  }
}
