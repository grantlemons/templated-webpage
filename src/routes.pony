use "files"
use "debug"
use "templates"
use "stallion"

class Page is RouteGet
  let _renderer: Renderer
  var _response: Response val = StatusResponse(StatusNotFound)
  var _size: USize = 0

  new home(file_auth: FileAuth) =>
    let title = "Lorem Ipsum"
    let date = "2026-07-01"
    let snippet = try CodeRenderer(file_auth, "assets/pygmentize.c").render()? else "" end

    let values = TemplateValues
    values("title") = title
    values("date") = date
    values.unescaped("snippet", snippet)
    _renderer = StyledRenderer(file_auth, "public/home.html", values)
    try bake_response()? end

  new any(file_auth: FileAuth, title: String val) =>
    let values = TemplateValues
    values("title") = title
    _renderer = StyledRenderer(file_auth, "public/" + title + ".html", values)
    try bake_response()? end

  new styles(file_auth: FileAuth) =>
    _renderer = RawRenderer(file_auth, "public/styles.css")
    try bake_response()? end

  new favicon(file_auth: FileAuth) =>
    _renderer = RawRenderer(file_auth, "public/favicon.ico")
    try bake_response()? end

  fun ref bake_response(): None ? =>
    let body = _renderer.render()?
    _response = OkResponse(body)
    _size = body.size()

  fun get(responder: (Responder ref | None)): USize =>
    _response.respond(responder)
    _size
