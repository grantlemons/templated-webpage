use "files"
use "debug"
use "templates"
use "stallion"

class Page is RouteGet
  let _renderer: Renderer

  new home(file_auth: FileAuth) =>
    let title = "Lorem Ipsum"
    let date = "2026-07-01"
    let snippet = try CodeRenderer(file_auth, "assets/pygmentize.c").render()? else "" end

    let values = TemplateValues
    values("title") = title
    values("date") = date
    values.unescaped("snippet", snippet)
    _renderer = StyledRenderer(file_auth, "public/home.html", values)

  new any(file_auth: FileAuth, title: String val) =>
    let values = TemplateValues
    values("title") = title
    _renderer = StyledRenderer(file_auth, "public/" + title + ".html", values)

  new styles(file_auth: FileAuth) =>
    _renderer = RawRenderer(file_auth, "public/styles.css")

  new favicon(file_auth: FileAuth) =>
    _renderer = RawRenderer(file_auth, "public/favicon.ico")

  fun get(responder: (Responder ref | None)): USize =>
    try
      let body = _renderer.render()?
      OkResponse(body).respond(responder)
      body.size()
    else
      StatusResponse(StatusNotFound).respond(responder)
      0
    end
