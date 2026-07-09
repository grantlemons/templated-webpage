use "files"
use "debug"
use "itertools"

primitive FileReader
  fun read(path: FilePath val): String val ? =>
    match OpenFile(path)
    | let file: File =>
      var res: String iso = String()
      while file.errno() is FileOK do
        res = res + file.read_string(1024)
      end
      res.strip()
      return res
    else
      Debug("Error opening file '" + path.path + "'")
      error
    end

class FileListWalkHandler
  var file_paths: Iter[FilePath val] ref = file_paths.maybe(None)

  fun ref apply(
    dir_path: FilePath val,
    dir_entries: Array[String val] ref
  ) =>
    try
      file_paths = Iter[FilePath val].chain(
        [
          file_paths
          DirectoryReader.keep_files(
            dir_path,
            Directory(dir_path)?.entries()?.values()
          )
        ].values()
      )
    end

primitive DirectoryReader
  fun keep_files(
    dir_path: FilePath val,
    entries: Iterator[String val] ref
  ): Iter[FilePath val] ref =>
    Iter[String val](entries)
      .filter_map[FilePath val]({(p) =>
        try
          let path: FilePath val = dir_path.join(p)?
          if FileInfo(path)?.file then path end
        end
      })

  fun keep_dirs(
    dir_path: FilePath val,
    entries: Iterator[String val] ref
  ): Iter[FilePath val] ref =>
    Iter[String val](entries)
      .filter_map[FilePath val]({(p) =>
        try
          let path: FilePath val = dir_path.join(p)?
          if FileInfo(path)?.directory then path end
        end
      })

  fun list_files(dir_path: FilePath val): Iter[FilePath val] ref =>
    try
      keep_files(dir_path, Directory(dir_path)?.entries()?.values())
    else
      Debug("Unable to get entries of " + dir_path.path)
      Iter[FilePath val].maybe(None)
    end

  fun list_dirs(dir_path: FilePath val): Iter[FilePath val] ref =>
    try
      keep_dirs(dir_path, Directory(dir_path)?.entries()?.values())
    else
      Debug("Unable to get entries of " + dir_path.path)
      Iter[FilePath val].maybe(None)
    end
