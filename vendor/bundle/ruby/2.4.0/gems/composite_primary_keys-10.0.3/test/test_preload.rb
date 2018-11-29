require File.expand_path('../abstract_unit', __FILE__)

class TestPreload < ActiveSupport::TestCase
  fixtures :comments, :users, :employees, :groups, :hacks

  class UserForPreload < User
    has_many :comments_with_include_condition, -> { where('person_type = ?', 'User')},
             class_name: 'Comment', foreign_key: 'person_id', as: :person
    has_many :comments_with_exclude_condition, -> { where('person_type <> ?', 'SomeType')},
             class_name: 'Comment', foreign_key: 'person_id', as: :person
  end

  class EmployeeForPreload < Employee
    # this is a rather random condition, which should not interfere with the normal test queries
    has_and_belongs_to_many :groups_2, class_name: 'Group', foreign_key: 'employee_id', join_table: 'employees_groups'
  end

  def test_preload_of_polymorphic_association
    comment = Comment.where(id: [1, 2, 3]).all
    persons = comment.map(&:person)
    persons.each do |person|
      assert_kind_of(ActiveRecord::Base, person)
    end

    comment = Comment.where(id: [1, 2, 3]).preload(:person).all
    persons = comment.map(&:person)
    persons.each do |person|
      assert_kind_of(ActiveRecord::Base, person)
    end
  end

  def test_preload_for_conditioned_has_many_association
    # has one comment
    user1 = users(:santiago)
    user2 = UserForPreload.create(name: 'TestPreload')
    Comment.create(person: user2, person_type: 'User')
    Comment.create(person: user2, person_type: 'User')

    users = UserForPreload.where(id: [user1.id, user2.id]).all
    assert_equal(1, users.first.comments_with_include_condition.size)
    assert_equal(2, users.second.comments_with_include_condition.size)

    users = UserForPreload.where(id: [user1.id, user2.id]).preload(:comments_with_include_condition).all
    assert_equal(1, users.first.comments_with_include_condition.size)
    assert_equal(2, users.second.comments_with_include_condition.size)

    users = UserForPreload.where(id: [user1.id, user2.id]).all
    assert_equal(1, users.first.comments_with_exclude_condition.size)
    assert_equal(2, users.second.comments_with_exclude_condition.size)

    users = UserForPreload.where(id: [user1.id, user2.id]).preload(:comments_with_exclude_condition).all
    assert_equal(1, users.first.comments_with_exclude_condition.size)
    assert_equal(2, users.second.comments_with_exclude_condition.size)
  end

  def test_preload_for_unconditioned_habtm_association
    employee1 = employees(:steve)
    employee2 = employees(:jill)
    employee1.groups = [groups(:cpk)]
    employee2.groups = [groups(:cpk), groups(:group2)]
    employee1.save!; employee2.save!

    employees = Employee.where(id: [1, 2]).all
    assert_equal(1, employees.first.groups.size)
    assert_equal(2, employees.second.groups.size)

    employees = Employee.where(id: [1, 2]).preload(:groups).all
    assert_equal(1, employees.first.groups.size)
    assert_equal(2, employees.second.groups.size)
  end

  def test_preload_for_conditioned_habtm_association
    employee1 = employees(:steve)
    employee2 = employees(:jill)
    employee1.groups = [groups(:cpk)]
    employee2.groups = [groups(:cpk), groups(:group2)]
    employee1.save!; employee2.save!

    employees = EmployeeForPreload.where(id: [1, 2]).all.order(:id)

    # Even without preload two errors: First Employee has Group 1 loaded twice,
    # Second Employee has only Group 2 instead of Group 1&2
    assert_equal(1, employees.first.groups.size)
    assert_equal(1, employees.first.groups_2.size)
    assert_equal(2, employees.second.groups.size)
    assert_equal(2, employees.second.groups_2.size)

    employees = EmployeeForPreload.where(id: [1, 2]).preload(:groups_2).all.order(:id)

    # with preloading, the first assertion is valid, but the second only gets Group 2 instead of 1&2
    assert_equal(1, employees.first.groups_2.size)
    assert_equal(2, employees.second.groups_2.size)
  end
end
