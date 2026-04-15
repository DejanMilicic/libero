import libero/walker

pub fn simple_pascal_case_test() {
  let assert "admin_data" = walker.to_snake_case("AdminData")
}

pub fn single_word_test() {
  let assert "one" = walker.to_snake_case("One")
}

pub fn three_words_test() {
  let assert "two_or_more" = walker.to_snake_case("TwoOrMore")
}

pub fn consecutive_uppercase_test() {
  let assert "xml_parser" = walker.to_snake_case("XMLParser")
}

pub fn all_caps_test() {
  let assert "html" = walker.to_snake_case("HTML")
}

pub fn single_char_test() {
  let assert "a" = walker.to_snake_case("A")
}

pub fn already_lowercase_test() {
  let assert "hello" = walker.to_snake_case("hello")
}

pub fn trailing_acronym_test() {
  let assert "parse_xml" = walker.to_snake_case("ParseXML")
}

pub fn leading_acronym_then_word_test() {
  let assert "http_request" = walker.to_snake_case("HTTPRequest")
}

pub fn number_in_name_test() {
  let assert "v3_mode" = walker.to_snake_case("V3Mode")
}
