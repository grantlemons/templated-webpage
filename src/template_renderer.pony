use "files"
use "debug"
use "templates"

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
