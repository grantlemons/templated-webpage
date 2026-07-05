use "stallion"

class NotFoundResponder
  let _response: Array[U8] val

  new create() =>
    _response = ResponseBuilder(StatusNotFound)
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun apply(responder: Responder ref) =>
    responder.respond(_response)

class InternalServerErrorResponder
  let _response: Array[U8] val

  new create() =>
    _response = ResponseBuilder(StatusInternalServerError)
      .add_header("Content-Length", "0")
      .finish_headers()
      .build()

  fun apply(responder: Responder ref) =>
    responder.respond(_response)

class OkResponder
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

  fun apply(responder: Responder ref) =>
    responder.respond(_response)
