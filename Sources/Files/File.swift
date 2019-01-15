import Clibc
import Darwin

public final class File {
  public let descriptor: Int32
  public let path: Path

  public init(_ path: Path) throws {
    self.descriptor = open(path._path, 0)
    guard self.descriptor >= 0 else { throw POSIXError.current(path) }
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
  public static func isDirectory(_ path: Path) -> Bool {
    return hawk_is_dir(path._path) == 1
  }
}
