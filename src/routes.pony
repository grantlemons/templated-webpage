use "files"
use "templates"
use "stallion"

class HomePage is PageGet
  let _env: Env
  let _renderer: RenderStyled
  let _values: TemplateValues box
  let title: String val
  let date: String val

  new create(env: Env, values': TemplateValues box = TemplateValues) =>
    title = "Lorem Ipsum"
    date = "2026-07-01"
    _env = env

    let values = values'.scope()
    values("title") = title
    values("date") = date
    values.unescaped("snippet", try RenderCode(FilePath.create(FileAuth(env.root), "pages/pygmentize.c"), env)()? else "" end)
    _values = values
    _renderer = RenderStyled("pages/home.html", "pages/styles.css", env, values)

  fun get(responder: Responder ref) =>
    let values = _values.scope()

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
    let values = TemplateValues
    values("title") = page
    _renderer = RenderStyled("pages" + page, "pages/styles.css", env, values)

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
