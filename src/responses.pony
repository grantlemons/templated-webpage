use "uri"
use "stallion"

trait Response
  fun response(): Array[U8] val
  fun apply() => response()
  fun respond(responder: Responder ref) =>
    responder.respond(response())

class RedirectResponse is Response
  let _response: Array[U8] val

  new create(uri: URI val) =>
    _response = ResponseBuilder(StatusMovedPermanently)
      .add_header("Location", uri.string())
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun response(): Array[U8] val => _response

class StatusResponse is Response
  let _response: Array[U8] val

  new create(status: Status val) =>
    _response = ResponseBuilder(status)
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun response(): Array[U8] val => _response

class OkResponse is Response
  let _response: Array[U8] val

  new create(body: String val, content_type: String val = "text/html") =>
    _response = ResponseBuilder(StatusOK)
      .add_header("Content-Type", content_type)
      .add_header("Content-Length", body.size().string())
      .finish_headers()
      .add_chunk(body)
      .build()

  new empty() =>
    _response = ResponseBuilder(StatusOK)
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun response(): Array[U8] val => _response
