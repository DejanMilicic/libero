import shared/todos

pub type AppError {
  TodoError(todos.TodoError)
}
