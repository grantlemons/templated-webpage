use "templates"
use "stallion"

class HomePage is PageGet
  let _env: Env
  let _renderer: RenderTemplated ref
  var title: String val
  var message: String val

  new create(env: Env) =>
    _env = env
    _renderer = RenderTemplated("pages/home.html", env)
    title = "Home"
    message = "Hello, World!"

  fun get(responder: Responder ref) =>
    let values = TemplateValues
    values("title") = title
    values("message") = message

    let res = try
        OkResponder(_renderer.apply(values)?)
      else
        InternalServerErrorResponder
      end
    res(responder)

class SiteCss is PageGet
  let _env: Env
  let _renderer: RenderUntemplated ref

  new create(env: Env) =>
    _env = env
    _renderer = RenderUntemplated("pages/styles.css", env)

  fun get(responder: Responder ref) =>
    let res = try
        OkResponder(_renderer.apply()?, "text/css")
      else
        NotFoundResponder
      end
    res(responder)

class Favicon is PageGet
  let _env: Env
  let _renderer: RenderUntemplated ref

  new create(env: Env) =>
    _env = env
    _renderer = RenderUntemplated("pages/favicon.ico", env)

  fun get(responder: Responder ref) =>
    let res = try
        OkResponder(_renderer.apply()?, "image/x-icon")
      else
        NotFoundResponder
      end
    res(responder)
