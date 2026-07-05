use "files"
use "ssl/net"
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
  var _https: stallion.HTTPServer = stallion.HTTPServer.none()
  let _router: Router
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
    _router = Router(env)
    _https = stallion.HTTPServer.ssl(auth, ssl_ctx, fd, this, config)

  fun ref _http_connection(): stallion.HTTPServer => _https
  
  fun ref on_request_complete(
    request: stallion.Request val,
    responder: stallion.Responder ref
  ) => _router(request, responder)
