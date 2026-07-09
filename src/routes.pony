use "files"
use "debug"
use "templates"
use "stallion"
use "collections"

class Page is RouteGet
  let _name: String val
  let _renderer: Renderer ref
  var _response: (Response val | None) = None
  var _size: USize = 0

  new fallback(file_auth: FileAuth, path: String val) =>
    _name = path
    let values = TemplateValues
    _renderer = StyledRenderer(file_auth, "pages" + path + "/index.html", values)
    bake_response()

  new styles(file_auth: FileAuth) =>
    _name = "/styles.css"
    _renderer = RawRenderer(file_auth, "public/styles.css")
    bake_response("text/css")

  new favicon(file_auth: FileAuth) =>
    _name = "/favicon.ico"
    _renderer = RawRenderer(file_auth, "public/favicon.ico")
    bake_response("img/ico")

  fun string(): String val => _name + ": " + _renderer.string()
  fun ref bake_response(content_type: String val = "text/html") =>
    try
      let body = _renderer.render()?
      _response = OkResponse(body, content_type)
      _size = body.size()
    end
    Debug("Rendered " + string())

  fun get(responder: (Responder ref | None)): USize =>
    match _response
    | let res: Response val => res.respond(responder)
    | None => StatusResponse(StatusNotFound)
    end
    _size
