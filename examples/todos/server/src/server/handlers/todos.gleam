import gleam/list
import server/app_error.{type AppError}
import server/shared_state.{type SharedState}
import shared/todos.{
  type ToClient, type ToServer, AllLoaded, Create, Created, Delete, Deleted,
  Error, LoadAll, NotFound, TitleRequired, Todo, Toggle, Toggled,
}

pub fn handle(
  msg msg: ToServer,
  state state: SharedState,
) -> Result(ToClient, AppError) {
  case msg {
    Create(params:) -> {
      case params.title {
        "" -> Ok(Error(TitleRequired))
        title -> {
          let new_todo = Todo(id: state.next_id, title:, completed: False)
          Ok(Created(new_todo))
        }
      }
    }
    Toggle(id:) -> {
      case list.find(state.todos, fn(t) { t.id == id }) {
        Ok(found) -> Ok(Toggled(Todo(..found, completed: !found.completed)))
        _ -> Ok(Error(NotFound))
      }
    }
    Delete(id:) -> {
      case list.find(state.todos, fn(t) { t.id == id }) {
        Ok(_) -> Ok(Deleted(id))
        _ -> Ok(Error(NotFound))
      }
    }
    LoadAll -> Ok(AllLoaded(state.todos))
  }
}
