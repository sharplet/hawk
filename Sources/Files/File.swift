import Clibc
import Darwin

public enum File {
  private static let nameOffset = MemoryLayout.offset(of: \dirent.d_name)!

  public static func forEachEntry(inDirectory path: String, _ body: (String) -> Void) {
    guard let dir = opendir(path) else { return }
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

  public static func isDirectory(_ path: String) -> Bool {
    return observer_is_dir(path) == 1
  }
}
