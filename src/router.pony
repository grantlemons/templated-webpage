use "uri"
use "collections"
use "stallion"

interface RequestHandler
  fun ref handle(request: Request val, responder: Responder ref)

trait Route
trait Context

class DummyContext is Context

// this is a trait because it will also apply Route
trait RouteGet is Route
  fun get(responder: Responder ref)
  fun head(responder: Responder ref) => OkResponse.empty().respond(responder)
interface RoutePost is Route
  fun post(responder: Responder ref, context: Context ref!)
interface RoutePut is Route
  fun put(responder: Responder ref, context: Context ref!)
interface RouteDelete is Route
  fun delete(responder: Responder ref, context: Context ref!)
interface RouteOptions is Route
  fun options(responder: Responder ref)
interface RoutePatch is Route
  fun patch(responder: Responder ref, context: Context ref!)

class HttpsRedirectHandler is RequestHandler
  let _env: Env
  let _host_uri: URI val

  new create(env: Env, host_uri: URI val) =>
    _env = env
    _host_uri = host_uri

  fun ref handle(request: Request val, responder: Responder ref) =>
    let uri: URI val = URI(
      "https",
      match _host_uri.authority
        | let auth: URIAuthority if auth.host != "0.0.0.0" => URIAuthority(None, auth.host, None)
      else URIAuthority(None, "localhost", None)
      end,
      request.uri.path,
      request.uri.query,
      request.uri.fragment
    )
    _env.out.print("Redirecting from " + request.uri.string() + " to " + uri.string())
    RedirectResponse(uri).respond(responder)

type RouteMap is Map[String val, Route]
class Router is RequestHandler
  let _env: Env
  let _context: Context ref!
  let _map: RouteMap

  new create(env: Env, context: Context ref = DummyContext) =>
    _env = env
    _context = context
    _map =
      RouteMap.create()
      .> insert("/", Page.home(env))
      .> insert("/styles", Page.styles(env))
      .> insert("/favicon.ico", Page.favicon(env))

  fun ref handle(request: Request val, responder: Responder ref) =>
    let page: (Route box | None) = try
      _map(request.uri.path)?
    else
      None
    end

    match (request.method, page)
      | (_, None) => StatusResponse(StatusNotFound).respond(responder)
      | (GET, let route': RouteGet box) => route'.get(responder)
      | (HEAD, let route': RouteGet box) => route'.head(responder)
      | (POST, let route': RoutePost box) => route'.post(responder, _context)
      | (PUT, let route': RoutePut box) => route'.put(responder, _context)
      | (DELETE, let route': RouteDelete box) => route'.delete(responder, _context)
      | (OPTIONS, let route': RouteOptions box) => route'.options(responder)
      | (PATCH, let route': RoutePatch box) => route'.patch(responder, _context)
    else
      _env.err.print("Unsupported HTTP method!")
      StatusResponse(StatusNotFound).respond(responder)
    end
