//// Tests for the Levenshtein distance function used by the
//// LikelyInjectTypo check. Verifies that near-miss labels like
//// tzdb/tz_db are caught while unrelated labels like key/lang
//// are not.

// levenshtein is private, so we test through a thin pub wrapper.
// The wrapper is only compiled into the test build.
import libero/levenshtein_helper

pub fn identical_strings_test() {
  let assert 0 = levenshtein_helper.distance("tz_db", "tz_db")
}

pub fn single_insertion_test() {
  // tzdb -> tz_db (insert underscore)
  let assert 1 = levenshtein_helper.distance("tzdb", "tz_db")
}

pub fn single_deletion_test() {
  let assert 1 = levenshtein_helper.distance("tz_db", "tzdb")
}

pub fn single_substitution_test() {
  let assert 1 = levenshtein_helper.distance("conn", "cont")
}

pub fn two_edits_test() {
  // connn -> conn (delete) then conn -> cont (substitute) = 2
  let assert 2 = levenshtein_helper.distance("connn", "cont")
}

pub fn completely_different_test() {
  // key vs lang = 4 edits (all different chars, different length)
  let assert True = levenshtein_helper.distance("key", "lang") > 2
}

pub fn empty_vs_nonempty_test() {
  let assert 5 = levenshtein_helper.distance("", "hello")
}

pub fn both_empty_test() {
  let assert 0 = levenshtein_helper.distance("", "")
}

pub fn real_world_inject_typo_test() {
  // The original issue: tzdb vs tz_db should be caught (distance 1)
  let assert True = levenshtein_helper.distance("tzdb", "tz_db") <= 2
}

pub fn real_world_false_positive_test() {
  // key vs lang should NOT be caught (distance > 2)
  let assert True = levenshtein_helper.distance("key", "lang") > 2
}

pub fn real_world_false_positive_slug_test() {
  // slug vs lang should NOT be caught
  let assert True = levenshtein_helper.distance("slug", "lang") > 2
}

pub fn real_world_false_positive_name_test() {
  // name vs conn should NOT be caught
  let assert True = levenshtein_helper.distance("name", "conn") > 2
}
