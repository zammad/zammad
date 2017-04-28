# encoding: utf-8
require 'test_helper'

class OrganizationDomainBasedAssignmentTest < ActiveSupport::TestCase
  test 'organization based assignment' do

    organization1 = Organization.create_if_not_exists(
      name: 'organization based assignment 1',
      domain: '@examPle1.com ',
      domain_assignment: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    organization2 = Organization.create_if_not_exists(
      name: 'organization based assignment 2',
      domain: 'example2.com',
      domain_assignment: false,
      updated_by_id: 1,
      created_by_id: 1,
    )

    roles = Role.where(name: 'Customer')
    customer1 = User.create_or_update(
      login: 'organization-based_assignment-customer1@example1.com',
      firstname: 'Domain',
      lastname: 'Agent1',
      email: 'organization-based_assignment-customer1@example1.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(organization1.id, customer1.organization_id)

    customer2 = User.create_or_update(
      login: 'organization-based_assignment-customer2@example1.com',
      firstname: 'Domain',
      lastname: 'Agent2',
      email: 'organization-based_assignment-customer2@example1.com',
      password: 'customerpw',
      active: true,
      organization_id: organization2.id,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_equal(organization2.id, customer2.organization_id)

    customer3 = User.create_or_update(
      login: 'organization-based_assignment-customer3@example2.com',
      firstname: 'Domain',
      lastname: 'Agent2',
      email: 'organization-based_assignment-customer3@example2.com',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(customer3.organization_id)

    customer4 = User.create_or_update(
      login: 'organization-based_assignment-customer4',
      firstname: 'Domain',
      lastname: 'Agent2',
      email: '@',
      password: 'customerpw',
      active: true,
      roles: roles,
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert_nil(customer4.organization_id)

  end

end
