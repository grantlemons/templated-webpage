use "files"
use "ssl/net"
use "uri"
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
            .> set_client_verify(true)
            .> set_server_verify(false)
        end
      else
        env.out.print("Unable to set up SSL context")
        return
      end

    let auth = lori.TCPListenAuth(env.root)
    Listener(env, auth, "0.0.0.0", "80", None)
    Listener(env, auth, "0.0.0.0", "443", sslctx)

actor Listener is lori.TCPListenerActor
  let _env: Env
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _config: stallion.ServerConfig
  let _server_auth: lori.TCPServerAuth
  let _ssl_ctx: (SSLContext val | None)
  let _handler: RequestHandler val

  new create(
    env: Env,
    auth: lori.TCPListenAuth,
    host: String,
    port: String,
    ssl_ctx: (SSLContext val | None)
  )
  =>
    _env = env
    _ssl_ctx = ssl_ctx
    _server_auth = lori.TCPServerAuth(auth)
    _config = stallion.ServerConfig(host, port)
    let host_uri = URI("http", URIAuthority(None, _config.host, try _config.port.u16()? end), "", None, None)
    _handler = match ssl_ctx
      | let _: SSLContext => Router(env)
      | None => HttpsRedirectHandler(env, host_uri)
    end
    _tcp_listener = lori.TCPListener(auth, host, port, this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_accept(fd: U32): lori.TCPConnectionActor tag =>
    Webserver(_env, _server_auth, fd, _config, _ssl_ctx, _handler)

  fun ref _on_listening() =>
    try
      (let host, let port) = _tcp_listener.local_address().name()?
      _env.out.print("HTTP server listening on " + host + ":" + port + ", handled by: " + _handler.name())
    else
      _env.out.print("HTTP server listening on " + _config.host + ":" + _config.port + ", handled by: " + _handler.name())
    end

  fun ref _on_listen_failure() =>
    _env.out.print("Failed to start server")

  fun ref _on_closed() =>
    _env.out.print("Server closed")

actor Webserver is stallion.HTTPServerActor
  let _env: Env
  var _http: stallion.HTTPServer = stallion.HTTPServer.none()
  let _handler: RequestHandler val

  new create(
    env: Env,
    auth: lori.TCPServerAuth,
    fd: U32,
    config: stallion.ServerConfig,
    ssl_ctx: (SSLContext val | None),
    handler: RequestHandler val
  )
  =>
    _env = env

    let host_uri = URI("http", URIAuthority(None, config.host, try config.port.u16()? end), "", None, None)
    _handler = handler
    _http = match ssl_ctx
      | let ssl_ctx': SSLContext => stallion.HTTPServer.ssl(auth, ssl_ctx', fd, this, config)
      | None => stallion.HTTPServer(auth, fd, this, config)
    end

  fun ref _http_connection(): stallion.HTTPServer => _http
  
  fun ref on_request_complete(
    request: stallion.Request val,
    responder: stallion.Responder ref
  ) => _handler.handle(request, responder)
