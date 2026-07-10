use "uri"
use "debug"
use "stallion"

trait Context
class DummyContext is Context
interface RequestHandler
  fun tag name(): String val
  fun val handle(request: Request val, responder: Responder ref, context: Context ref = DummyContext)


class HttpsRedirectHandler is RequestHandler
  let _host_uri: URI val

  new val create(host_uri: URI val) =>
    _host_uri = host_uri

  fun tag name(): String val => "Https Redirector"

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
    Debug("Redirecting from " + request.uri.string() + " to " + uri.string())
    RedirectResponse(uri).respond(responder)
