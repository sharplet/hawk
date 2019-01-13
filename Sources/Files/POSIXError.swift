import Foundation

struct POSIXError: Error {
  static func current(_ context: Any? = nil) -> POSIXError {
    return POSIXError(code: errno, message: context.map(String.init(describing:)))
  }

  let code: Int32
  let message: String?
}

extension POSIXError: LocalizedError {
  var errorDescription: String? {
    return message
  }

  var failureReason: String? {
    return String(cString: strerror(code))
  }
}
