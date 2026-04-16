/// CLI client for the todos example.
/// Sends MsgFromClient messages to the server via HTTP POST and
/// prints the MsgFromServer responses. No libero dependency needed —
/// just native ETF encoding over HTTP.

import gleam/io
import gleam/string
import shared/todos.{
  type MsgFromServer, AllLoaded, Create, Created, Delete, Deleted, LoadAll,
  TodoFailed, TodoParams, Toggle, Toggled,
}

pub fn main() {
  let url = "http://localhost:8080/rpc"

  io.println("=== Libero CLI Example ===")
  io.println("Connecting to " <> url)
  io.println("")

  // Ensure inets is started for httpc
  start_inets()

  // 1. Load all (should be empty or have existing items)
  io.println("Loading all todos...")
  let response = rpc(url, "shared/todos", LoadAll)
  print_response(response)

  // 2. Create a todo
  io.println("Creating \"Buy milk\"...")
  let response = rpc(url, "shared/todos", Create(TodoParams(title: "Buy milk")))
  print_response(response)

  // 3. Create another
  io.println("Creating \"Walk the dog\"...")
  let response =
    rpc(url, "shared/todos", Create(TodoParams(title: "Walk the dog")))
  print_response(response)

  // 4. Load all again
  io.println("Loading all todos...")
  let response = rpc(url, "shared/todos", LoadAll)
  print_response(response)

  // 5. Toggle todo 1
  io.println("Toggling todo 1...")
  let response = rpc(url, "shared/todos", Toggle(id: 1))
  print_response(response)

  // 6. Delete todo 2
  io.println("Deleting todo 2...")
  let response = rpc(url, "shared/todos", Delete(id: 2))
  print_response(response)

  // 7. Final state
  io.println("Final state:")
  let response = rpc(url, "shared/todos", LoadAll)
  print_response(response)
}

fn print_response(result: Result(MsgFromServer, String)) {
  case result {
    Ok(msg) -> {
      case msg {
        AllLoaded(items) -> {
          case items {
            [] -> io.println("  (empty)")
            _ ->
              items
              |> list_each(fn(item) {
                let check = case item.completed {
                  True -> "[x]"
                  False -> "[ ]"
                }
                io.println(
                  "  "
                  <> check
                  <> " #"
                  <> int_to_string(item.id)
                  <> " "
                  <> item.title,
                )
              })
          }
        }
        Created(item) ->
          io.println(
            "  Created: #"
            <> int_to_string(item.id)
            <> " "
            <> item.title,
          )
        Toggled(item) -> {
          let status = case item.completed {
            True -> "completed"
            False -> "active"
          }
          io.println(
            "  Toggled: #"
            <> int_to_string(item.id)
            <> " "
            <> item.title
            <> " ("
            <> status
            <> ")",
          )
        }
        Deleted(id:) -> io.println("  Deleted: #" <> int_to_string(id))
        TodoFailed(err) ->
          io.println("  Failed: " <> string.inspect(err))
      }
      io.println("")
    }
    Error(reason) -> {
      io.println("  ERROR: " <> reason)
      io.println("")
    }
  }
}

// -- Erlang FFI --

/// Send a MsgFromClient to the server via HTTP POST, receive MsgFromServer.
@external(erlang, "cli_ffi", "rpc")
fn rpc(
  url: String,
  module: String,
  msg: a,
) -> Result(MsgFromServer, String)

@external(erlang, "cli_ffi", "start_inets")
fn start_inets() -> Nil

@external(erlang, "cli_ffi", "int_to_string")
fn int_to_string(n: Int) -> String

@external(erlang, "cli_ffi", "list_each")
fn list_each(items: List(a), f: fn(a) -> Nil) -> Nil
