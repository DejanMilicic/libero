import lustre
import lustre/element
import lustre/element/html

pub fn main() {
  let app = lustre.element(view())
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn view() -> element.Element(msg) {
  html.div([], [
    html.h1([], [html.text("web")]),
    html.p([], [html.text("Edit this file to get started.")]),
  ])
}
