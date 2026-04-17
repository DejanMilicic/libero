import core/app_error.{type AppError}
import core/messages.{
  type MsgFromClient, type MsgFromServer, Create, Delete, LoadAll, NotFound,
  TitleRequired, Todo, TodoCreated, TodoDeleted, TodoToggled, TodosLoaded,
  Toggle,
}
import core/shared_state.{type SharedState}

/// Handle RPC messages from clients.
///
/// This example returns static responses. A real app would use ETS
/// or a database for persistence.
pub fn update_from_client(
  msg msg: MsgFromClient,
  state state: SharedState,
) -> Result(#(MsgFromServer, SharedState), AppError) {
  case msg {
    Create(params:) ->
      case params.title {
        "" -> Ok(#(TodoCreated(Error(TitleRequired)), state))
        title -> {
          let item = Todo(id: 1, title:, completed: False)
          Ok(#(TodoCreated(Ok(item)), state))
        }
      }
    Toggle(id: _id) -> Ok(#(TodoToggled(Error(NotFound)), state))
    Delete(id: _id) -> Ok(#(TodoDeleted(Error(NotFound)), state))
    LoadAll -> Ok(#(TodosLoaded(Ok([])), state))
  }
}
