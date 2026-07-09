use "files"
use "debug"
use "collections"
use "stallion"

type Route is (RouteGet | RoutePost | RoutePut | RouteDelete | RouteOptions | RoutePatch)

interface RouteGet
  fun get(responder: (Responder ref | None)): USize
  fun head(responder: (Responder ref | None)): USize =>
    let size = get(None)
    OkResponse.empty_size(size).respond(responder)
    size
interface RoutePost
  fun post(responder: Responder ref, context: Context ref!)
interface RoutePut
  fun put(responder: Responder ref, context: Context ref!)
interface RouteDelete
  fun delete(responder: Responder ref, context: Context ref!)
interface RouteOptions
  fun options(responder: Responder ref)
interface RoutePatch
  fun patch(responder: Responder ref, context: Context ref!)

type RouteMap is Map[String val, Route]
class Router is RequestHandler
  let _file_auth: FileAuth
  let _map: RouteMap

  new val create(file_auth: FileAuth) =>
    _file_auth = file_auth
    _map =
      RouteMap.create()
      .> insert("/", Page.home(file_auth))
      .> insert("/styles", Page.styles(file_auth))
      .> insert("/favicon.ico", Page.favicon(file_auth))

  fun tag name(): String val => "Router"

  fun val handle(request: Request val, responder: Responder ref, context: Context ref = DummyContext) =>
    let page: Route box = try
      _map(request.uri.path)?
    else
      Page.fallback(_file_auth, request.uri.path)
    end

    match (request.method, page)
      | (GET, let route': RouteGet box) =>
          route'.get(responder)
          None
      | (HEAD, let route': RouteGet box) =>
          route'.head(responder)
          None
      | (POST, let route': RoutePost box) => route'.post(responder, context)
      | (PUT, let route': RoutePut box) => route'.put(responder, context)
      | (DELETE, let route': RouteDelete box) => route'.delete(responder, context)
      | (OPTIONS, let route': RouteOptions box) => route'.options(responder)
      | (PATCH, let route': RoutePatch box) => route'.patch(responder, context)
    else
      Debug("Unsupported HTTP method!")
      StatusResponse(StatusNotFound).respond(responder)
    end
