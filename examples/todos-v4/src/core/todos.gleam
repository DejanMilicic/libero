pub type Todo {
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

/// Each response variant carries a `Result(payload, TodoError)` so the
/// libero `to_remote` helper can collapse it into a `RemoteData` value
/// at the call site. Domain errors travel inside `Error(_)`; framework
/// errors (panic, unknown function) travel separately as `AppError` and
/// are surfaced by libero's default formatter.
pub type MsgFromServer {
  TodoCreated(Result(Todo, TodoError))
  TodoToggled(Result(Todo, TodoError))
  TodoDeleted(Result(Int, TodoError))
  TodosLoaded(Result(List(Todo), TodoError))
}
