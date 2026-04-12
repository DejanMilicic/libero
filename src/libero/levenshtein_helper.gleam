//// Thin public wrapper around the generator's levenshtein function,
//// exposed only so tests can exercise it directly. Not part of
//// libero's public API.

import gleam/list
import gleam/string

/// Levenshtein distance between two strings.
pub fn distance(a: String, b: String) -> Int {
  let a_chars = string.to_graphemes(a)
  let b_chars = string.to_graphemes(b)
  let b_len = list.length(b_chars)

  let init_row = build_range(from: 0, to: b_len)

  let #(final_row, _) =
    list.fold(a_chars, #(init_row, 1), fn(state, a_char) {
      let #(prev_row, i) = state
      let #(new_row_rev, _) =
        list.fold(b_chars, #([i], 1), fn(inner, b_char) {
          let #(row_so_far, j) = inner
          let assert [above, ..] = row_so_far
          let diag = list_at(prev_row, j - 1)
          let left = above
          let up = list_at(prev_row, j)
          let cost = case a_char == b_char {
            True -> 0
            False -> 1
          }
          let val = min3(a: diag + cost, b: left + 1, c: up + 1)
          #([val, ..row_so_far], j + 1)
        })
      #(list.reverse(new_row_rev), i + 1)
    })

  let assert Ok(d) = list.last(final_row)
  d
}

fn build_range(from from: Int, to to: Int) -> List(Int) {
  case from > to {
    True -> []
    False -> [from, ..build_range(from: from + 1, to: to)]
  }
}

fn list_at(items: List(Int), index: Int) -> Int {
  case items, index {
    [x, ..], 0 -> x
    [_, ..rest], n -> list_at(rest, n - 1)
    [], _ -> 0
  }
}

fn min3(a a: Int, b b: Int, c c: Int) -> Int {
  let ab = case a < b {
    True -> a
    False -> b
  }
  case ab < c {
    True -> ab
    False -> c
  }
}
