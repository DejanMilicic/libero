import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/option.{None}
import gleam/string
import mist
import server/shared_state
import server/websocket as ws

pub fn main() {
  let shared = shared_state.new()

  let assert Ok(_) =
    fn(req) {
      case request.path_segments(req) {
        ["ws"] ->
          mist.websocket(
            request: req,
            handler: ws.handler,
            on_init: ws.on_init(shared),
            on_close: fn(_state) { Nil },
          )
        ["js", ..path] ->
          serve_file("../client/build/dev/javascript/" <> string.join(path, "/"), "application/javascript")
        _ ->
          serve_file("priv/static/index.html", "text/html")
      }
    }
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
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
