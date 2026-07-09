use "files"
use "debug"

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
