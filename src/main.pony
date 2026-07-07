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
    Listener(auth, "0.0.0.0", "80", None, env)
    Listener(auth, "0.0.0.0", "443", sslctx, env)

actor Listener is lori.TCPListenerActor
  var _tcp_listener: lori.TCPListener = lori.TCPListener.none()
  let _config: stallion.ServerConfig
  let _server_auth: lori.TCPServerAuth
  let _ssl_ctx: (SSLContext val | None)
  let _env: Env

  new create(
    auth: lori.TCPListenAuth,
    host: String,
    port: String,
    ssl_ctx: (SSLContext val | None),
    env: Env
  )
  =>
    _env = env
    _ssl_ctx = ssl_ctx
    _server_auth = lori.TCPServerAuth(auth)
    _config = stallion.ServerConfig(host, port)
    _tcp_listener = lori.TCPListener(auth, host, port, this)

  fun ref _listener(): lori.TCPListener => _tcp_listener

  fun ref _on_accept(fd: U32): lori.TCPConnectionActor tag =>
    Webserver(_server_auth, fd, _config, _ssl_ctx, _env)

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

actor Webserver is stallion.HTTPServerActor
  var _http: stallion.HTTPServer = stallion.HTTPServer.none()
  let _handler: RequestHandler
  let _env: Env

  new create(
    auth: lori.TCPServerAuth,
    fd: U32,
    config: stallion.ServerConfig,
    ssl_ctx: (SSLContext val | None),
    env: Env
  )
  =>
    _env = env

    let host_uri = URI("http", URIAuthority(None, config.host, try config.port.u16()? end), "", None, None)
    _handler = match ssl_ctx
      | let _: SSLContext => Router(env)
      | None => HttpsRedirectHandler(env, host_uri)
    end
    _http = match ssl_ctx
      | let ssl_ctx': SSLContext => stallion.HTTPServer.ssl(auth, ssl_ctx', fd, this, config)
      | None => stallion.HTTPServer(auth, fd, this, config)
    end

  fun ref _http_connection(): stallion.HTTPServer => _http
  
  fun ref on_request_complete(
    request: stallion.Request val,
    responder: stallion.Responder ref
  ) => _handler.handle(request, responder)
