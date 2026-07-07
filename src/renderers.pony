use "files"
use "templates"
use @system[I32](command: Pointer[U8] tag)

interface Renderer
  fun render( values: TemplateValues box = TemplateValues): String val ?

class FileReader
  let _env: Env

  new create(env: Env) => _env = env

  fun read_path(path: FilePath val): String val ? =>
    _env.out.print("Opening file " + path.path)
    match OpenFile(path)
    | let file: File =>
      var res: String iso = String()
      while file.errno() is FileOK do
        res = res + file.read_string(1024)
      end
      res.strip()
      return res
    else
      _env.err.print("Error opening file '" + path.path + "'")
      error
    end

  fun apply(path: String val): String val ? =>
    read_path(FilePath(FileAuth(_env.root), path))?

class TemplateRenderer is Renderer
  let _path: String val
  let _env: Env
  let _values: TemplateValues box

  new create(
    env: Env,
    path: String val,
    values: TemplateValues box = TemplateValues
  ) =>
    _env = env
    _path = path
    _values = values

  fun render(
    values: TemplateValues box = TemplateValues
  ): String val ? =>
    let template = HtmlTemplate.parse(UntemplatedRenderer(_env, _path).render()?)?
    try
      template.render(values)?
    else
      _env.err.print("Unable to render templated file " + _path)
      error
    end
  fun apply(values: TemplateValues): String val ? => render(values)?
    

class UntemplatedRenderer is Renderer
  let _path: String val
  let _env: Env

  new create(env: Env, path: String val) =>
    _env = env
    _path = path

  fun render(
    values: TemplateValues box = TemplateValues
  ): String val ? => FileReader(_env)(_path)?
  fun apply(): String val ? => render()?

class StyledRenderer is Renderer
  let _env: Env
  var _values: TemplateValues box
  let _template_renderer: TemplateRenderer
  let _body_renderer: Renderer
  let _style_renderer: Renderer

  new create(
    env: Env,
    body_path: String val,
    values: TemplateValues box = TemplateValues,
    stylesheet_path: String val = "public/styles.css",
    template_path: String val = "assets/template.html"
  ) =>
    _env = env
    _template_renderer = TemplateRenderer(env, template_path)
    _body_renderer = TemplateRenderer(env, body_path)
    _style_renderer = UntemplatedRenderer(env, stylesheet_path)
    _values = values
    _values = _prev_next_scope(consume values)

  fun _prev_next_scope(
    values': TemplateValues box = TemplateValues
  ): TemplateValues box =>
    let values = values'.scope()
    values("prev") = "https://devmail.group/"
    values("next") = "https://byronsharman.com/"
    values

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
  let _env: Env
  let _path: FilePath val
  let _output_path: FilePath val

  new create(env: Env, path: String val) =>
    _env = env
    _path = FilePath.create(FileAuth(env.root), path)
    _output_path = FilePath.create(FileAuth(env.root), path + ".html")
    try generate()? end

  // TODO: behavior?
  fun generate(): None ? =>
    if not _path.exists() then error end
    if not _output_path.exists() then
      let command = "pygmentize -f html -O style=solarized-light -o " + _output_path.path + " " + _path.path
      if @system(command.cstring()) != 0 then error end
    end

  fun render(values: TemplateValues box = TemplateValues): String val ? =>
    generate()? // ensure the file has not been deleted
    FileReader(_env).read_path(_output_path)?
  fun apply(): String val ? => render()?
