use "files"
use templates = "templates"

class FileReader
  let _out: OutStream
  let _err: OutStream

  new create(env: Env) =>
    _out = env.out
    _err = env.err

  fun apply(path: FilePath): String val ? =>
    match OpenFile(path)
    | let file: File =>
      var res: String iso = String()
      while file.errno() is FileOK do
        res = res + file.read_string(1024)
      end
      res.strip()
      return res
    else
      _err.print("Error opening file '" + path.path + "'")
      error
    end

class RenderTemplated
  let path: String val
  let _env: Env
  let _file_auth: FileAuth
  var _file_content: (templates.HtmlTemplate | None) = None

  new create(path': String val, env: Env) =>
    path = path'
    _env = env
    _file_auth = FileAuth(env.root)

  new cooked(path': String val, env: Env) =>
    path = path'
    _env = env
    _file_auth = FileAuth(env.root)
    try
      cook()?
    end

  fun ref cook(): None ? =>
    _file_content = try
        templates.HtmlTemplate.parse(FileReader(_env)(FilePath(_file_auth, path))?)?
      else
        _env.err.print("Could not parse template")
        error
      end

  fun ref apply(values: templates.TemplateValues): String val ? =>
    match _file_content
      | let content: templates.HtmlTemplate => content.render(values)?
      | None =>
        cook()?
        apply(values)?
    end
