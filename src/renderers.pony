use "files"
use "debug"
use "templates"
use @system[I32](command: Pointer[U8] tag)

interface Renderer
  fun ref load()
  fun render( values: TemplateValues box = TemplateValues): String val ?

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

class TemplateRenderer is Renderer
  let _path: String val
  let _values: TemplateValues box
  var _renderer: Renderer ref

  new create(
    file_auth: FileAuth,
    path: String val,
    values: TemplateValues box = TemplateValues
  ) =>
    _path = path
    _values = values
    _renderer = RawRenderer(file_auth, path)

  fun ref load() => _renderer.load()
  fun render(
    values: TemplateValues box = TemplateValues
  ): String val ? =>
    let template = HtmlTemplate.parse(_renderer.render()?)?
    try
      template.render(values)?
    else
      Debug("Unable to render templated file " + _path)
      error
    end
  fun apply(values: TemplateValues): String val ? => render(values)?
    

class RawRenderer is Renderer
  let _file_auth: FileAuth
  let _path: String val
  var _file_content: (String val | None) = None

  new create(file_auth: FileAuth, path: String val) =>
    _file_auth = file_auth
    _path = path
    load()
  
  new unloaded(file_auth: FileAuth, path: String val) =>
    _file_auth = file_auth
    _path = path

  fun _read(path: String val): String val ? =>
    FileReader.read(FilePath(_file_auth, path))?

  fun ref load() => 
    Debug("Rendering " + _path)
    try _file_content = _read(_path)? end

  fun render(
    values: TemplateValues box = TemplateValues
  ): String val ? => match _file_content
      | let content: String val => content
      | None => _read(_path)?
    end
  fun apply(): String val ? => render()?

class StyledRenderer is Renderer
  let _file_auth: FileAuth
  var _values: TemplateValues box
  var _template_renderer: TemplateRenderer ref
  var _body_renderer: Renderer ref
  var _style_renderer: Renderer ref

  new create(
    file_auth: FileAuth,
    body_path: String val,
    values: TemplateValues box = TemplateValues,
    stylesheet_path: String val = "public/styles.css",
    template_path: String val = "assets/template.html"
  ) =>
    _file_auth = file_auth
    _template_renderer = TemplateRenderer(file_auth, template_path)
    _body_renderer = TemplateRenderer(file_auth, body_path)
    _style_renderer = RawRenderer(file_auth, stylesheet_path)
    _values = values
    _values = _prev_next_scope(consume values)

  fun _prev_next_scope(
    values': TemplateValues box = TemplateValues
  ): TemplateValues box =>
    let values = values'.scope()
    values("prev") = "https://devmail.group/"
    values("next") = "https://byronsharman.com/"
    values

  fun ref load() =>
    _template_renderer.load()
    _body_renderer.load()
    _style_renderer.load()
  fun render(
    body_values: TemplateValues box = TemplateValues
  ): String val ? =>
    let values = _values.scope()
    values.unescaped("styles", _style_renderer.render()?)
    values.unescaped("body", _body_renderer.render(body_values)?)
    _template_renderer.render(values)?
  fun apply(
    values: TemplateValues box = TemplateValues
  ): String val ? => render(values)?

class CodeRenderer is Renderer
  let _file_auth: FileAuth
  let _path: FilePath val
  let _output_path: FilePath val
  var _renderer: Renderer ref

  new create(file_auth: FileAuth, path: String val) =>
    _file_auth = file_auth
    _path = FilePath.create(_file_auth, path)

    _output_path = FilePath.create(_file_auth, path + ".html")
    _renderer = RawRenderer.unloaded(_file_auth, _output_path.path)
    load()

  // TODO: behavior?
  fun generate(): None ? =>
    if not _path.exists() then error end
    if not _output_path.exists() then
      let command = "pygmentize -f html -O style=solarized-light -o " + _output_path.path + " " + _path.path
      if @system(command.cstring()) != 0 then error end
    end

  fun ref load() =>
    try
      generate()?
      _renderer.load()
    end
  fun render(values: TemplateValues box = TemplateValues): String val ? =>
    _renderer.render()?
  fun apply(): String val ? => render()?
