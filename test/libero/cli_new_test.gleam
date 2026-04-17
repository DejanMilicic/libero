import gleam/string
import libero/cli/new as cli_new
import simplifile

pub fn scaffold_project_test() {
  let dir = "test/tmp/scaffold_test"
  let _ = simplifile.delete(dir)

  let assert Ok(Nil) = cli_new.scaffold(name: "my_app", path: dir)

  let assert Ok(True) = simplifile.is_file(dir <> "/libero.toml")
  let assert Ok(True) = simplifile.is_file(dir <> "/gleam.toml")
  let assert Ok(True) = simplifile.is_directory(dir <> "/src/core")

  let assert Ok(toml) = simplifile.read(dir <> "/libero.toml")
  let assert True = string.contains(toml, "name = \"my_app\"")

  let assert Ok(gleam_toml) = simplifile.read(dir <> "/gleam.toml")
  let assert True = string.contains(gleam_toml, "name = \"my_app\"")
  let assert True = string.contains(gleam_toml, "target = \"erlang\"")

  let assert Ok(True) = simplifile.is_file(dir <> "/src/core/todos.gleam")
  let assert Ok(True) = simplifile.is_file(dir <> "/src/core/todos_handler.gleam")
  let assert Ok(True) = simplifile.is_file(dir <> "/src/core/shared_state.gleam")
  let assert Ok(True) = simplifile.is_file(dir <> "/src/core/app_error.gleam")

  let _ = simplifile.delete(dir)
  Nil
}
