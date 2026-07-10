use "files"
use "debug"
use "templates"
use "stallion"
use "collections"

class Page is RouteGet
  let _name: String val
  let _renderer: Renderer ref
  var _content_type: String val = "text/html"
  var _response: (Response val | None) = None
  var _size: USize = 0

  new fallback(file_auth: FileAuth, path: String val) =>
    _name = path
    let body_path: String val = "pages" + path + "/index.html"
    _renderer = DependencyRenderer(
      file_auth,
      body_path,
      StyledRenderer(file_auth, body_path)
    )
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
    _content_type = content_type
    try
      let body = _renderer.render()?
      _response = OkResponse(body, content_type)
      _size = body.size()
    else
      Debug("ERROR: failed to render " + _name)
    end
    Debug("Rendered " + string())

  fun get(responder: (Responder ref | None)): USize =>
    (let response, let size) = 
      match _response
      | let res: Response val => (res, _size)
      | None => try
          let body = _renderer.render()?
          (OkResponse(body, _content_type), body.size())
        else
          (StatusResponse(StatusNotFound), 0)
        end
      end
    response.respond(responder)
    size
