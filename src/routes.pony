use "files"
use "debug"
use "templates"
use "stallion"
use "collections"

class Page is RouteGet
  let _renderer: Renderer ref
  var _response: (Response val | None) = None
  var _size: USize = 0

  new home(file_auth: FileAuth) =>
    let values = TemplateValues
    _renderer = StyledRenderer(file_auth, "pages/home/index.html", values)
    bake_response()

  new fallback(file_auth: FileAuth, path: String val) =>
    let values = TemplateValues
    _renderer = StyledRenderer(file_auth, "pages" + path + "/index.html", values)
    bake_response()

  new styles(file_auth: FileAuth) =>
    _renderer = RawRenderer(file_auth, "public/styles.css")
    bake_response()

  new favicon(file_auth: FileAuth) =>
    _renderer = RawRenderer(file_auth, "public/favicon.ico")
    bake_response()

  fun ref bake_response(content_type: String val = "text/html") =>
    try
      let body = _renderer.render()?
      _response = OkResponse(body, content_type)
      _size = body.size()
    end

  fun get(responder: (Responder ref | None)): USize =>
    match _response
      | let res: Response val => res.respond(responder)
      | None => StatusResponse(StatusNotFound)
    end
    _size
