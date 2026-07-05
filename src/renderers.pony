use "files"
use "templates"

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
  var _file_content: (HtmlTemplate | None) = None

  new create(path': String val, env: Env) =>
    path = path'
    _env = env
    _file_auth = FileAuth(env.root)
    _file_content = try
        HtmlTemplate.parse(FileReader(_env)(FilePath(_file_auth, path))?)?
      else
        _env.err.print("Could not parse template")
      end

  fun apply(values: TemplateValues): String val ? =>
    match _file_content
      | let content: HtmlTemplate => content.render(values)?
      else
        error
    end

class RenderUntemplated
  let path: String val
  let _env: Env
  let _file_auth: FileAuth
  var _file_content: (String val | None) = None

  new create(path': String val, env: Env) =>
    path = path'
    _env = env
    _file_auth = FileAuth(env.root)
    _file_content = try
        FileReader(_env)(FilePath(_file_auth, path))?
      else
        _env.err.print("Could not read file!")
      end

  fun apply(): String val ? =>
    match _file_content
      | let content: String => content
      else
        _env.err.print("No content!")
        error
    end

class RenderStyled
  let body_path: String val
  let style_path: String val
  let _env: Env
  let _renderer: RenderTemplated
  var _body_renderer: RenderTemplated
  var _style_renderer: RenderUntemplated

  new create(body_path': String val, style_path': String val, env: Env) =>
    body_path = body_path'
    style_path = style_path'
    _env = env
    _renderer = RenderTemplated("pages/template.html", env)
    _body_renderer = RenderTemplated(body_path, _env)
    _style_renderer = RenderUntemplated(style_path, _env)

  fun apply(body_values: TemplateValues): String val ? =>
    let values = TemplateValues
    values.unescaped("styles", _style_renderer()?)
    values.unescaped("body", _body_renderer(body_values)?)
    
    _renderer(values)?
