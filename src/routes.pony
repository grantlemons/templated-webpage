use "files"
use "templates"
use "stallion"

class Page is RouteGet
  let _env: Env
  let _renderer: Renderer

  new home(env: Env) =>
    _env = env
    let title = "Lorem Ipsum"
    let date = "2026-07-01"
    let snippet = try CodeRenderer(env, "assets/pygmentize.c").render()? else "" end

    let values = TemplateValues
    values("title") = title
    values("date") = date
    values.unescaped("snippet", snippet)
    _renderer = StyledRenderer(env, "public/home.html", values)

  new any(env: Env, title: String val) =>
    _env = env
    let values = TemplateValues
    values("title") = title
    _renderer = StyledRenderer(env, "public/" + title + ".html", values)

  new styles(env: Env) =>
    _env = env
    _renderer = RawRenderer(env, "public/styles.css")

  new favicon(env: Env) =>
    _env = env
    _renderer = RawRenderer(env, "public/favicon.ico")

  fun get(responder: (Responder ref | None)): USize =>
    try
      let body = _renderer.render()?
      OkResponse(body).respond(responder)
      body.size()
    else
      StatusResponse(StatusNotFound).respond(responder)
      0
    end
