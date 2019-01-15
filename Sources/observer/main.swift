import Dispatch
import Files
import Foundation

func showError(_ error: Error) {
  var message = error.localizedDescription
  if let failureReason = (error as NSError).localizedFailureReason {
    message += ": \(failureReason)"
  }
  fputs("fatal: \(message)\n", stderr)
}

@discardableResult
func handleSignal(_ signal: Int32, execute body: @escaping () -> Void) -> DispatchSourceSignal {
  let source = DispatchSource.makeSignalSource(signal: signal, queue: .main)
  source.setEventHandler(handler: body)
  source.setCancelHandler { _ = source }
  source.resume()
  return source
}

let app = App { app, error in
  showError(error)
  app.exit(failure: true)
}

let interruptHandler: () -> Void = {
  app.exit()
}

handleSignal(SIGHUP, execute: interruptHandler)
handleSignal(SIGINT, execute: interruptHandler)

let paths = CommandLine.arguments.dropFirst().map(Path.init)
app.startObserving(paths)
app.run()
