use "files"
use "debug"
use "templates"
use @system[I32](command: Pointer[U8] tag)

interface Renderer is Stringable
  fun ref load()
  fun render(values: TemplateValues box = TemplateValues): String val ?

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

  fun string(): String iso^ => "TemplateRenderer -> " + _path
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

  fun string(): String iso^ => "RawRenderer -> " + _path
  fun ref load() => 
    try _file_content = _read(_path)? end

  fun render(
    values: TemplateValues box = TemplateValues
  ): String val ? => match _file_content
      | let content: String val => content
      | None => error
    end
  fun apply(): String val ? => render()?

primitive PrevNextValues
  fun scoped(
    values': TemplateValues box = TemplateValues
  ): TemplateValues box =>
    let values = values'.scope()
    values("prev") = "https://devmail.group/"
    values("next") = "https://byronsharman.com/"
    values

class StyledRenderer is Renderer
  let _file_auth: FileAuth
  var _template_renderer: TemplateRenderer ref
  var _body_renderer: Renderer ref
  var _style_renderer: Renderer ref

  new create(
    file_auth: FileAuth,
    body_path: String val,
    stylesheet_path: String val = "public/styles.css",
    template_path: String val = "pages/template.html"
  ) =>
    _file_auth = file_auth
    _template_renderer = TemplateRenderer(file_auth, template_path)
    _body_renderer = TemplateRenderer(file_auth, body_path)
    _style_renderer = RawRenderer(file_auth, stylesheet_path)

  fun string(): String iso^ =>
    let res: String ref = recover String end
    res.append("StyledRenderer ")
    for (name, renderer) in [
      ("template", _template_renderer)
      ("style", _style_renderer)
      ("body", _body_renderer)
    ].values() do
      let child_str: String ref = renderer.string()
      child_str.replace("\t", "\t\t") // extra level of indent
      res.append("\n\t." + name + " -> " + child_str)
    end
    res.string()

  fun ref load() =>
    _template_renderer.load()
    _body_renderer.load()
    _style_renderer.load()
  fun render(
    values: TemplateValues box = TemplateValues
  ): String val ? =>
    let values' = values.scope()
    values'.unescaped("styles", _style_renderer.render()?)
    values'.unescaped("body", _body_renderer.render(values)?)
    _template_renderer.render(values')?
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

  fun string(): String iso^ =>
    let child_str: String val = _renderer.string()
    "CodeRenderer -> " + child_str
  fun ref load() =>
    try
      generate()?
      _renderer.load()
    end
  fun render(values: TemplateValues box = TemplateValues): String val ? =>
    _renderer.render()?
  fun apply(): String val ? => render()?
