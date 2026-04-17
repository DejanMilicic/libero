import core/handler
import core/messages.{Create, LoadAll, TodoParams, TodosLoaded}
import core/shared_state
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn load_all_returns_empty_list_test() {
  let state = shared_state.new()
  let assert Ok(#(TodosLoaded(Ok([])), _)) =
    handler.update_from_client(msg: LoadAll, state:)
}

pub fn create_with_empty_title_returns_error_test() {
  let state = shared_state.new()
  let assert Ok(#(messages.TodoCreated(Error(messages.TitleRequired)), _)) =
    handler.update_from_client(
      msg: Create(params: TodoParams(title: "")),
      state:,
    )
}

pub fn create_with_title_returns_todo_test() {
  let state = shared_state.new()
  let assert Ok(#(messages.TodoCreated(Ok(messages.Todo(1, "Buy milk", False))), _)) =
    handler.update_from_client(
      msg: Create(params: TodoParams(title: "Buy milk")),
      state:,
    )
}
