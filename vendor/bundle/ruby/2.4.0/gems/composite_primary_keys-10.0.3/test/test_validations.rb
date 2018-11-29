require File.expand_path('../abstract_unit', __FILE__)

class TestValidations < ActiveSupport::TestCase
  fixtures :students, :dorms, :rooms, :room_assignments

  def test_uniqueness_validation_persisted
    room_assignment = RoomAssignment.find([1, 1, 1])
    assert(room_assignment.valid?)

    room_assignment = RoomAssignment.new(:student_id => 1, :dorm_id => 1, :room_id => 2)
    assert(!room_assignment.valid?)
  end
end
