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

pub type ToServer {
  Create(params: TodoParams)
  Toggle(id: Int)
  Delete(id: Int)
  LoadAll
}

pub type ToClient {
  Created(Todo)
  Toggled(Todo)
  Deleted(id: Int)
  AllLoaded(List(Todo))
  TodoFailed(TodoError)
}
