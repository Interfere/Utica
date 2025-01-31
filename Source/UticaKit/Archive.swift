import Foundation
import ReactiveSwift
import ReactiveTask
import Result

/// Zips the given input paths (recursively) into an archive that will be
/// located at the given URL.
public func zip(paths: [String], into archiveURL: URL, workingDirectory: String) -> SignalProducer<Void, CarthageError> {
  precondition(!paths.isEmpty)
  precondition(archiveURL.isFileURL)

  let task = Task("/usr/bin/env", arguments: ["zip", "-q", "-r", "--symlinks", archiveURL.path] + paths, workingDirectoryPath: workingDirectory)

  return task.launch()
    .mapError(CarthageError.taskError)
    .then(SignalProducer<Void, CarthageError>.empty)
}

/// Unarchives the given file URL into a temporary directory, using its
/// extension to detect archive type, then sends the file URL to that directory.
public func unarchive(archive fileURL: URL) -> SignalProducer<URL, CarthageError> {
  switch fileURL.pathExtension {
    case "gz", "tgz", "bz2", "xz":
      return untar(archive: fileURL)
    default:
      return unzip(archive: fileURL)
  }
}

/// Unzips the archive at the given file URL, extracting into the given
/// directory URL (which must already exist).
private func unzip(archive fileURL: URL, to destinationDirectoryURL: URL) -> SignalProducer<Void, CarthageError> {
  precondition(fileURL.isFileURL)
  precondition(destinationDirectoryURL.isFileURL)

  let task = Task("/usr/bin/env", arguments: ["unzip", "-uo", "-qq", "-d", destinationDirectoryURL.path, fileURL.path])
  return task.launch()
    .mapError(CarthageError.taskError)
    .then(SignalProducer<Void, CarthageError>.empty)
}

/// Untars an archive at the given file URL, extracting into the given
/// directory URL (which must already exist).
private func untar(archive fileURL: URL, to destinationDirectoryURL: URL) -> SignalProducer<Void, CarthageError> {
  precondition(fileURL.isFileURL)
  precondition(destinationDirectoryURL.isFileURL)

  let task = Task("/usr/bin/env", arguments: ["tar", "-xf", fileURL.path, "-C", destinationDirectoryURL.path])
  return task.launch()
    .mapError(CarthageError.taskError)
    .then(SignalProducer<Void, CarthageError>.empty)
}

private let archiveTemplate = "utica-archive.XXXXXX"

/// Unzips the archive at the given file URL into a temporary directory, then
/// sends the file URL to that directory.
private func unzip(archive fileURL: URL) -> SignalProducer<URL, CarthageError> {
  return FileManager.default.reactive.createTemporaryDirectoryWithTemplate(archiveTemplate)
    .flatMap(.merge) { directoryURL in
      unzip(archive: fileURL, to: directoryURL)
        .then(SignalProducer<URL, CarthageError>(value: directoryURL))
    }
}

/// Untars an archive at the given file URL into a temporary directory,
/// then sends the file URL to that directory.
private func untar(archive fileURL: URL) -> SignalProducer<URL, CarthageError> {
  return FileManager.default.reactive.createTemporaryDirectoryWithTemplate(archiveTemplate)
    .flatMap(.merge) { directoryURL in
      untar(archive: fileURL, to: directoryURL)
        .then(SignalProducer<URL, CarthageError>(value: directoryURL))
    }
}
