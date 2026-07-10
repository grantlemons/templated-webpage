use "files"
use "debug"
use "templates"

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
      ("style", _style_renderer)
      ("body", _body_renderer)
    ].values() do
      let child_str: String ref = renderer.string()
      child_str.replace("\t", "\t\t") // extra level of indent
      res.append("\n\t." + name + " -> " + child_str)
    end
    let child_str: String ref = _template_renderer.string()
    child_str.replace("\t", "\t\t") // extra level of indent
    res.add("\n\t-> " + child_str)

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
