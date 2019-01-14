import Dispatch
import Files
import Foundation

@discardableResult
func handleInterrupt(execute body: @escaping () -> Void) -> DispatchSourceSignal {
  signal(SIGINT, SIG_IGN)
  let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
  source.setEventHandler(handler: body)
  source.setCancelHandler { _ = source }
  source.resume()
  return source
}

do {
  let app = App()
  let paths = CommandLine.arguments.dropFirst().map(Path.init)
  try app.startObserving(paths)
  handleInterrupt(execute: app.exit)
  app.run()
} catch {
  var message = error.localizedDescription
  if let failureReason = (error as NSError).localizedFailureReason {
    message += ": \(failureReason)"
  }
  fputs("fatal: \(message)\n", stderr)
  exit(1)
}
