import Darwin
import Dispatch

let paths = CommandLine.arguments.dropFirst()
var sources: [DispatchSourceFileSystemObject] = []

for path in paths {
  guard case let fd = open(path, O_EVTONLY),
    fd >= 0
    else { perror(path); continue }

  let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fd,
    eventMask: [.attrib, .delete, .rename, .write],
    queue: .main
  )

  sources.append(source)

  source.setCancelHandler {
    close(fd)
  }

  var count = 0

  source.setEventHandler {
    let event: String

    switch source.data {
    case .attrib:
      event = "attrib"
    case .delete:
      event = "delete"
    case .rename:
      event = "rename"
    case .write:
      event = "write"
    default:
      return
    }

    count += 1

    print("\(event): \(path) (\(count))")
  }

  source.resume()
}

dispatchMain()
