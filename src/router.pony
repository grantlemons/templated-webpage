use "uri"
use "collections"
use "stallion"

interface Router
  fun ref route(request: Request val, responder: Responder ref)

trait Page
trait Context

class DummyContext is Context

// this is a trait because it will also apply Page
trait PageGet is Page
  fun get(responder: Responder ref)
  fun head(responder: Responder ref) => OkResponder.empty()(responder)
interface PagePost is Page
  fun post(responder: Responder ref, context: Context ref!)
interface PagePut is Page
  fun put(responder: Responder ref, context: Context ref!)
interface PageDelete is Page
  fun delete(responder: Responder ref, context: Context ref!)
interface PageOptions is Page
  fun options(responder: Responder ref)
interface PagePatch is Page
  fun patch(responder: Responder ref, context: Context ref!)

class HttpsRedirectRouter is Router
  let _env: Env
  let _host_uri: URI val

  new create(env: Env, host_uri: URI val) =>
    _env = env
    _host_uri = host_uri

  fun ref route(request: Request val, responder: Responder ref) =>
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
    RedirectResponder(uri)(responder)

type RouteMap is Map[String val, Page]
class PageRouter is Router
  let _env: Env
  let _context: Context ref!
  let _map: RouteMap

  new create(env: Env, context: Context ref = DummyContext) =>
    _env = env
    _context = context
    _map =
      RouteMap.create()
      .> insert("/", HomePage.create(env))
      .> insert("/styles", SiteCss.create(env))
      .> insert("/favicon.ico", Favicon.create(env))

  fun ref route(request: Request val, responder: Responder ref) =>
    let page: (Page box | None) = try
      _map(request.uri.path)?
    else
      None
    end

    match (request.method, page)
      | (_, None) => NotFoundResponder(responder)
      | (GET, let page': PageGet box) => page'.get(responder)
      | (HEAD, let page': PageGet box) => page'.head(responder)
      | (POST, let page': PagePost box) => page'.post(responder, _context)
      | (PUT, let page': PagePut box) => page'.put(responder, _context)
      | (DELETE, let page': PageDelete box) => page'.delete(responder, _context)
      | (OPTIONS, let page': PageOptions box) => page'.options(responder)
      | (PATCH, let page': PagePatch box) => page'.patch(responder, _context)
    else
      _env.err.print("Unsupported HTTP method!")
      NotFoundResponder(responder)
    end
