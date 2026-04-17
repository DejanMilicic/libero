//// Template strings for `libero new` scaffolding.
////
//// Each function returns a file's content as a String. The generated
//// files give a new project a runnable todos example out of the box.

/// Returns libero.toml content for a new project.
pub fn libero_toml(name name: String) -> String {
  "name = \""
  <> name
  <> "\"
port = 8080
"
}

/// Returns gleam.toml content for a new project.
pub fn gleam_toml(name name: String) -> String {
  "name = \""
  <> name
  <> "\"
version = \"0.1.0\"
target = \"erlang\"

[dependencies]
gleam_stdlib = \">= 0.69.0 and < 1.0.0\"
lustre = \"~> 5.6\"
libero = { path = \"../libero\" }

[dev-dependencies]
gleeunit = \"~> 1.0\"
"
}

/// Returns a starter todos messages module.
///
/// Defines the core domain types and the typed RPC boundary between
/// client and server that libero uses to generate dispatch/send code.
pub fn starter_messages() -> String {
  "pub type Todo {
  Todo(id: Int, title: String, completed: Bool)
}

pub type TodoParams {
  TodoParams(title: String)
}

pub type TodoError {
  NotFound
  TitleRequired
}

pub type MsgFromClient {
  Create(params: TodoParams)
  Toggle(id: Int)
  Delete(id: Int)
  LoadAll
}

pub type MsgFromServer {
  TodoCreated(Result(Todo, TodoError))
  TodoToggled(Result(Todo, TodoError))
  TodoDeleted(Result(Int, TodoError))
  TodosLoaded(Result(List(Todo), TodoError))
}
"
}

/// Returns a starter handler module.
///
/// Implements `update_from_client` — the single entry point that libero's
/// generated dispatch table calls for every inbound RPC from the client.
pub fn starter_handler() -> String {
  "import core/app_error.{type AppError}
import core/shared_state.{type SharedState}
import core/todos.{
  type MsgFromClient, type MsgFromServer, Create, Delete, LoadAll, NotFound,
  TitleRequired, Todo, TodoCreated, TodoDeleted, TodoToggled, TodosLoaded,
  Toggle,
}

/// Handle an RPC message from the client.
///
/// Domain errors (NotFound, TitleRequired) are wrapped in the response
/// variant's Result so the client surfaces them through RemoteData
/// just like successes. Reserve AppError for framework-level failures.
pub fn update_from_client(
  msg msg: MsgFromClient,
  state state: SharedState,
) -> Result(#(MsgFromServer, SharedState), AppError) {
  case msg {
    Create(params:) -> {
      case params.title {
        \"\" -> Ok(#(TodoCreated(Error(TitleRequired)), state))
        _title -> Ok(#(TodoCreated(Error(NotFound)), state))
      }
    }
    Toggle(id: _id) -> Ok(#(TodoToggled(Error(NotFound)), state))
    Delete(id: _id) -> Ok(#(TodoDeleted(Error(NotFound)), state))
    LoadAll -> Ok(#(TodosLoaded(Ok([])), state))
  }
}
"
}

/// Returns a starter SharedState module.
///
/// SharedState is a unit type — actual state lives in ETS or a process.
/// This satisfies the dispatch.handle(state:, data:) signature that
/// libero generates.
pub fn starter_shared_state() -> String {
  "/// SharedState is a unit type — actual state lives in ETS or a process.
/// This satisfies the dispatch.handle(state:, data:) signature
/// that libero generates.
pub type SharedState {
  SharedState
}

pub fn new() -> SharedState {
  SharedState
}
"
}

/// Returns a starter AppError module.
///
/// Framework-level errors only. Domain errors live inside each
/// MsgFromServer variant's Result.
pub fn starter_app_error() -> String {
  "/// Framework-level errors only. Domain errors live inside each
/// MsgFromServer variant's Result. Libero treats AppError values as
/// opaque — a panic, an unknown RPC, or a handler returning
/// Error(app_err) all surface to the client through RpcError rather
/// than through a typed MsgFromServer payload.
pub type AppError {
  AppError(reason: String)
}
"
}

/// Returns a starter Lustre SPA app module.
pub fn starter_spa(name name: String) -> String {
  "import gleam/io
import lustre

pub fn main() -> Nil {
  io.println(\"Starting "
  <> name
  <> " SPA...\")
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, \"#app\", Nil)
  Nil
}

fn init(_flags) {
  #(Nil, [])
}

fn update(model, _msg) {
  #(model, [])
}

fn view(_model) {
  import lustre/element/html
  html.div([], [])
}
"
}

/// Returns a starter CLI main module.
pub fn starter_cli() -> String {
  "import gleam/io

pub fn main() -> Nil {
  io.println(\"Hello from your Libero app!\")
}
"
}
