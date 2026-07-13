use "uri"
use "stallion"

trait Response
  fun response(): Array[U8] val
  fun apply() => response()
  fun respond(responder: (Responder ref | None)) =>
    match responder
    | let responder': Responder ref => responder'.respond(response())
    end

class val RedirectResponse is Response
  let _response: Array[U8] val

  new val create(uri: URI val) =>
    _response = ResponseBuilder(StatusMovedPermanently)
      .add_header("Location", uri.string())
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun response(): Array[U8] val => _response

class val StatusResponse is Response
  let _response: Array[U8] val

  new val create(status: Status val) =>
    _response = ResponseBuilder(status)
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun response(): Array[U8] val => _response

class val OkResponse is Response
  let _response: Array[U8] val

  new val create(body: String val, content_type: String val = "text/html") =>
    _response = ResponseBuilder(StatusOK)
      .add_header("Content-Type", content_type)
      .add_header("Content-Length", body.size().string())
      .finish_headers()
      .add_chunk(body)
      .build()

  new val empty_size(size: USize, content_type: String val = "text/html") =>
    _response = ResponseBuilder(StatusOK)
      .add_header("Content-Type", content_type)
      .add_header("Content-Length", size.string())
      .finish_headers()
      .build()

  new val empty() =>
    _response = ResponseBuilder(StatusOK)
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun response(): Array[U8] val => _response
