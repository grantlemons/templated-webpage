use "templates"
use "stallion"

class HomePage is PageGet
  let _env: Env
  let _renderer: RenderStyled
  var title: String val
  var message: String val

  new create(env: Env) =>
    _env = env
    _renderer = RenderStyled("pages/home.html", "pages/styles.css", env)
    title = "Home"
    message = "Hello, World!"

  fun get(responder: Responder ref) =>
    let values = TemplateValues
    values("title") = title
    values("message") = message

    let response = try
        OkResponse(_renderer.apply(values)?)
      else
        StatusResponse(StatusNotFound)
      end
    response.respond(responder)

class AnyPage is PageGet
  let _env: Env
  let _renderer: RenderStyled

  new create(env: Env, page: String val) =>
    _env = env
    _renderer = RenderStyled("pages" + page, "pages/styles.css", env)

  fun get(responder: Responder ref) =>
    let response = try
        OkResponse(_renderer.apply(TemplateValues)?)
      else
        StatusResponse(StatusNotFound)
      end
    response.respond(responder)

class SiteCss is PageGet
  let _env: Env
  let _renderer: RenderUntemplated

  new create(env: Env) =>
    _env = env
    _renderer = RenderUntemplated("pages/styles.css", env)

  fun get(responder: Responder ref) =>
    let response = try
        OkResponse(_renderer.apply()?)
      else
        StatusResponse(StatusNotFound)
      end
    response.respond(responder)

class Favicon is PageGet
  let _env: Env
  let _renderer: RenderUntemplated

  new create(env: Env) =>
    _env = env
    _renderer = RenderUntemplated("pages/favicon.ico", env)

  fun get(responder: Responder ref) =>
    let response = try
        OkResponse(_renderer.apply()?)
      else
        StatusResponse(StatusNotFound)
      end
    response.respond(responder)
