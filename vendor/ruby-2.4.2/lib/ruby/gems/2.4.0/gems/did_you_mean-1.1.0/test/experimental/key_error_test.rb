require "test_helper"

class ExperimentalKeyErrorNameCorrectionTest < Minitest::Test
  def test_corrects_hash_key_name
    hash = { "foo" => 1, bar: 2 }

    error = assert_raises(KeyError) { hash.fetch(:bax) }
    assert_correction ":bar", error.corrections
    assert_match "Did you mean?  :bar", error.to_s

    error = assert_raises(KeyError) { hash.fetch("fooo") }
    assert_correction %("foo"), error.corrections
    assert_match %(Did you mean?  "foo"), error.to_s
  end
end
