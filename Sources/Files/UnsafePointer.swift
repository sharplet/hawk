extension UnsafeMutablePointer {
  func load<Value>(_ keyPath: KeyPath<Pointee, Value>) -> Value? {
    guard let offset = MemoryLayout<Pointee>.offset(of: keyPath) else {
      return nil
    }

    return UnsafeRawPointer(self).load(fromByteOffset: offset, as: Value.self)
  }
}
