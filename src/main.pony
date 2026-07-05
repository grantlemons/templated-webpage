use "files"
use "ssl/net"
use templates = "templates"
use stallion = "stallion"
use lori = "lori"

actor Main
  new create(env: Env) =>
    let file_auth = FileAuth(env.root)
    let sslctx =
      try
        recover val
          SSLContext
            .> set_authority(
              FilePath(file_auth, "assets/cert.pem"))?
            .> set_cert(
              FilePath(file_auth, "assets/cert.pem"),
              FilePath(file_auth, "assets/key.pem"))?
            .> set_client_verify(false)
            .> set_server_verify(false)
        end
      else
        env.out.print("Unable to set up SSL context")
        return
      end

    let auth = lori.TCPListenAuth(env.root)
    Listener(auth, "0.0.0.0", "8443", sslctx, env)

actor Listener is lori.TCPListenerActor
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _config: stallion.ServerConfig
  let _server_auth: lori.TCPServerAuth
  let _ssl_ctx: SSLContext val
  let _env: Env

  new create(
    auth: lori.TCPListenAuth,
    host: String,
    port: String,
    ssl_ctx: SSLContext val,
    env: Env
  )
  =>
    _env = env
    _ssl_ctx = ssl_ctx
    _server_auth = lori.TCPServerAuth(auth)
    _config = stallion.ServerConfig(host, port)
    _tcp_listener = lori.TCPListener(auth, host, port, this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_accept(fd: U32): lori.TCPConnectionActor =>
    HelloServer(_server_auth, fd, _config, _ssl_ctx, _env)

  fun ref _on_listening() =>
    try
      (let host, let port) = _tcp_listener.local_address().name()?
      _env.out.print("HTTPS server listening on " + host + ":" + port)
    else
      _env.out.print("HTTPS server listening")
    end

  fun ref _on_listen_failure() =>
    _env.out.print("Failed to start server")

  fun ref _on_closed() =>
    _env.out.print("Server closed")

actor HelloServer is stallion.HTTPServerActor
  var _http: stallion.HTTPServer = stallion.HTTPServer.none()
  let _env: Env

  new create(
    auth: lori.TCPServerAuth,
    fd: U32,
    config: stallion.ServerConfig,
    ssl_ctx: SSLContext val,
    env: Env
  )
  =>
    _env = env
    _http = stallion.HTTPServer.ssl(auth, ssl_ctx, fd, this, config)

  fun ref _http_connection(): stallion.HTTPServer => _http
  
  fun path_request(request: stallion.Request val): (String val | None) ? =>
    match (request.method, request.uri.path)
      | (stallion.GET, "/") => HomePage(_env).render_get()?
      else
        None
    end

  fun ref on_request_complete(request: stallion.Request val,
    responder: stallion.Responder)
  =>
    let response = try
      match path_request(request)?
        | let resp_body': String val =>
          _env.out.print("OK: " + request.uri.path)
          stallion.ResponseBuilder(stallion.StatusOK)
            .add_header("Content-Type", "text/html")
            .add_header("Content-Length", resp_body'.size().string())
            .finish_headers()
            .add_chunk(resp_body')
            .build()
        | None => 
          _env.out.print("NotFound: " + request.uri.path)
          stallion.ResponseBuilder(stallion.StatusNotFound)
            .add_header("Content-Length", "0")
            .finish_headers()
            .build()
      end
    else
      _env.err.print("InternalServerError: " + request.uri.path)
      stallion.ResponseBuilder(stallion.StatusInternalServerError)
        .add_header("Content-Length", "0")
        .finish_headers()
        .build()
    end
    responder.respond(response)

class HomePage
  let _env: Env
  let _renderer: RenderTemplated ref
  var title: String val
  var message: String val

  new create(env: Env) =>
    _env = env
    _renderer = RenderTemplated.cooked("pages/home.html", env)
    title = "Home"
    message = "Hello, World!"

  fun ref apply(): String val ? => render_get()?

  fun ref render_get(): String val ? =>
    let values = templates.TemplateValues
    values("title") = title
    values("message") = message

    _renderer.apply(values)?
