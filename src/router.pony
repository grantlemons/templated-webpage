use "uri"
use "collections"
use "stallion"

interface RequestHandler
  fun tag name(): String val
  fun val handle(request: Request val, responder: Responder ref, context: Context ref = DummyContext)

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

  new val create(env: Env, host_uri: URI val) =>
    _env = env
    _host_uri = host_uri

  fun tag name(): String val => "Https Redirect Handler"

  fun val handle(request: Request val, responder: Responder ref, context: Context ref = DummyContext) =>
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
  let _map: RouteMap

  new val create(env: Env) =>
    _env = env
    _map =
      RouteMap.create()
      .> insert("/", Page.home(env))
      .> insert("/styles", Page.styles(env))
      .> insert("/favicon.ico", Page.favicon(env))

  fun tag name(): String val => "Router"

  fun val handle(request: Request val, responder: Responder ref, context: Context ref = DummyContext) =>
    let page: (Route box | None) = try
      _map(request.uri.path)?
    else
      None
    end

    match (request.method, page)
      | (_, None) => StatusResponse(StatusNotFound).respond(responder)
      | (GET, let route': RouteGet box) => route'.get(responder)
      | (HEAD, let route': RouteGet box) => route'.head(responder)
      | (POST, let route': RoutePost box) => route'.post(responder, context)
      | (PUT, let route': RoutePut box) => route'.put(responder, context)
      | (DELETE, let route': RouteDelete box) => route'.delete(responder, context)
      | (OPTIONS, let route': RouteOptions box) => route'.options(responder)
      | (PATCH, let route': RoutePatch box) => route'.patch(responder, context)
    else
      _env.err.print("Unsupported HTTP method!")
      StatusResponse(StatusNotFound).respond(responder)
    end
