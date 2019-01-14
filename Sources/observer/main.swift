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
func handleInterrupt(execute body: @escaping () -> Void) -> DispatchSourceSignal {
  signal(SIGINT, SIG_IGN)
  let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
  source.setEventHandler(handler: body)
  source.setCancelHandler { _ = source }
  source.resume()
  return source
}

let app = App { app, error in
  showError(error)
  app.exit(failure: true)
}

handleInterrupt {
  app.exit()
}

let paths = CommandLine.arguments.dropFirst().map(Path.init)
app.startObserving(paths)
app.run()
