import shared/todos.{type Todo}

pub type SharedState {
  SharedState(next_id: Int, todos: List(Todo))
}

pub fn new() -> SharedState {
  SharedState(next_id: 1, todos: [])
}
