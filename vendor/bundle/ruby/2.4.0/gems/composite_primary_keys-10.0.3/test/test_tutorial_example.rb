require File.expand_path('../abstract_unit', __FILE__)

class TestTutorialExample < ActiveSupport::TestCase
  fixtures :users, :groups, :memberships, :membership_statuses
  
  def test_membership
    membership = Membership.find([1, 1])
    assert(membership, "Cannot find a membership")
    assert(membership.user)
    assert(membership.group)
  end
  
  def test_status
    membership = Membership.find([1, 1])
    statuses = membership.statuses
    assert(membership, "Cannot find a membership")
    assert(statuses, "No has_many association to status")
    assert_equal(membership, statuses.first.membership)
  end
  
  def test_count
    membership = Membership.find([1, 1])
    assert(membership, "Cannot find a membership")
    assert_equal(1, membership.statuses.count)
  end
end