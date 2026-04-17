import gleam/bit_array
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/option.{None}
import gleam/string
import libero/push
import libero/remote_data.{NotAsked, Success}
import libero/wire
import libero/ws_logger
import lustre/element
import mist
import server/generated/libero/dispatch
import server/generated/libero/websocket as ws
import server/shared_state
import server/store
import shared/todos.{LoadAll}
import shared/views.{Model}

pub fn main() {
  store.init()
  push.init()
  let shared = shared_state.new()

  let assert Ok(_) =
    fn(req: request.Request(mist.Connection)) {
      case req.method, request.path_segments(req) {
        _, ["ws"] ->
          ws.upgrade(
            request: req,
            state: shared,
            topics: ["todos"],
            logger: ws_logger.default_logger(),
          )
        http.Post, ["rpc"] -> handle_rpc(req, shared)
        _, ["js", ..path] ->
          serve_file(
            "../client/build/dev/javascript/" <> string.join(path, "/"),
            "application/javascript",
          )
        _, _ -> handle_ssr(shared)
      }
    }
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}

fn handle_ssr(
  shared: shared_state.SharedState,
) -> response.Response(mist.ResponseData) {
  // Call dispatch directly with LoadAll
  let call = wire.encode_call(module: "shared/todos", msg: LoadAll)
  let #(response_bytes, _, _) = dispatch.handle(state: shared, data: call)

  // Wire response has a 1-byte tag prefix, then Result(payload, RpcError) in ETF.
  let assert <<_tag, etf_payload:bytes>> = response_bytes
  let assert Ok(items) = wire.decode_safe(etf_payload)

  // Build model and render view
  let model = Model(items: Success(items), input: "", last_action: NotAsked)
  let rendered = element.to_string(views.view(model))

  // Encode items as base64 ETF for client flags
  let flags_etf = wire.encode(items)
  let flags_b64 = bit_array.base64_encode(flags_etf, True)

  // Build HTML document
  let html =
    "<!doctype html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\" />\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n  <title>Todos - hydration example</title>\n</head>\n<body>\n  <div id=\"app\">"
    <> rendered
    <> "</div>\n  <script>window.__LIBERO_FLAGS__ = \""
    <> flags_b64
    <> "\";</script>\n  <script type=\"module\">\n    import { main } from \"/js/client/client/app.mjs\";\n    main();\n  </script>\n</body>\n</html>"

  response.new(200)
  |> response.set_header("content-type", "text/html")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(html)))
}

fn handle_rpc(
  req: request.Request(mist.Connection),
  shared: shared_state.SharedState,
) -> response.Response(mist.ResponseData) {
  case mist.read_body(req, 1_000_000) {
    Ok(req) -> {
      let #(response_bytes, _maybe_panic, _new_state) =
        dispatch.handle(state: shared, data: req.body)
      response.new(200)
      |> response.set_header("content-type", "application/octet-stream")
      |> response.set_body(
        mist.Bytes(bytes_tree.from_bit_array(response_bytes)),
      )
    }
    Error(_) ->
      response.new(400)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("Bad request")))
  }
}

fn serve_file(
  path: String,
  content_type: String,
) -> response.Response(mist.ResponseData) {
  case mist.send_file(path, offset: 0, limit: None) {
    Ok(body) ->
      response.new(200)
      |> response.set_header("content-type", content_type)
      |> response.set_body(body)
    Error(_) ->
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("Not found")))
  }
}
