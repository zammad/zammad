require File.expand_path('../abstract_unit', __FILE__)

class TestSerialization < ActiveSupport::TestCase
  fixtures :departments

  def test_json
    department = Department.first
    assert_equal('{"department_id":1,"location_id":1}', department.to_json)
  end

  def test_serializable_hash
    department = Department.first
    assert_equal({"department_id" => 1,"location_id" => 1}, department.serializable_hash)
  end
end