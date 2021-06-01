# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class OrganizationCsvImportTest < ActiveSupport::TestCase

  test 'import example verify' do
    csv_string = Organization.csv_example

    rows = CSV.parse(csv_string)
    header = rows.shift
    assert_equal('id', header[0])
    assert_equal('name', header[1])
    assert_equal('shared', header[2])
    assert_equal('domain', header[3])
    assert_equal('domain_assignment', header[4])
    assert_equal('active', header[5])
    assert_equal('note', header[6])
    assert(header.include?('members'))
  end

  test 'empty payload' do
    csv_string = ''
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_nil(result[:records])
    assert_equal('failed', result[:result])
    assert_equal('Unable to parse empty file/string for Organization.', result[:errors][0])

    csv_string = 'id;name;shared;domain;domain_assignment;active;'
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert(result[:records].blank?)
    assert_equal('failed', result[:result])
    assert_equal('No records found in file/string for Organization.', result[:errors][0])
  end

  test 'verify required lookup headers' do
    csv_string = "firstname;lastname;active;\nfirstname-simple-import1;lastname-simple-import1;;true\nfirstname-simple-import2;lastname-simple-import2;false\n"
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal('failed', result[:result])
    assert_equal('No lookup column like id,name for Organization found.', result[:errors][0])
  end

  test 'simple import' do

    csv_string = "id;name;shared;domain;domain_assignment;active;note\n;org-simple-import1;true;org-simple-import1.example.com;false;true;some note1\n;org-simple-import2;true;org-simple-import2.example.com;false;false;some note2\n"
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(Organization.find_by(name: 'org-simple-import1'))
    assert_nil(Organization.find_by(name: 'org-simple-import2'))

    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )
    assert_equal(false, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    organization1 = Organization.find_by(name: 'org-simple-import1')
    assert(organization1)
    assert_equal(organization1.name, 'org-simple-import1')
    assert_equal(organization1.shared, true)
    assert_equal(organization1.domain, 'org-simple-import1.example.com')
    assert_equal(organization1.domain_assignment, false)
    assert_equal(organization1.note, 'some note1')
    assert_equal(organization1.active, true)
    organization2 = Organization.find_by(name: 'org-simple-import2')
    assert(organization2)
    assert_equal(organization2.name, 'org-simple-import2')
    assert_equal(organization2.shared, true)
    assert_equal(organization2.domain, 'org-simple-import2.example.com')
    assert_equal(organization2.domain_assignment, false)
    assert_equal(organization2.note, 'some note2')
    assert_equal(organization2.active, false)

    organization1.destroy!
    organization2.destroy!
  end

  test 'simple import with invalid id' do

    csv_string = "id;name;shared;domain;domain_assignment;active;note;\n999999999;organization-simple-invalid_id-import1;\n;organization-simple-invalid_id-import2;\n"
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal(1, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: unknown Organization with id '999999999'.", result[:errors][0])

    assert_nil(Organization.find_by(name: 'organization-simple-invalid_id-import1'))
    assert_nil(Organization.find_by(name: 'organization-simple-invalid_id-import2'))

    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )
    assert_equal(false, result[:try])
    assert_equal(1, result[:records].count)
    assert_equal('failed', result[:result])

    assert_nil(Organization.find_by(name: 'organization-simple-invalid_id-import1'))

    # any single failure will cause the entire import to be aborted
    assert_nil(Organization.find_by(name: 'organization-simple-invalid_id-import2'))
  end

  test 'simple import with members' do
    UserInfo.current_user_id = 1

    name = rand(999_999_999)
    customer1 = User.create_or_update(
      login:     "customer1-members#{name}@example.com",
      firstname: 'Member',
      lastname:  "Customer#{name}",
      email:     "customer1-members#{name}@example.com",
      password:  'customerpw',
      active:    true,
    )
    customer2 = User.create_or_update(
      login:     "customer2-members#{name}@example.com",
      firstname: 'Member',
      lastname:  "Customer#{name}",
      email:     "customer2-members#{name}@example.com",
      password:  'customerpw',
      active:    true,
    )

    csv_string = "id;name;members;\n;organization-member-import1;\n;organization-member-import2;#{customer1.email}\n;;#{customer2.email}"
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )

    assert_equal(true, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(Organization.find_by(name: 'organization-member-import1'))
    assert_nil(Organization.find_by(name: 'organization-member-import2'))

    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )

    assert_equal(false, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    organization1 = Organization.find_by(name: 'organization-member-import1')
    assert(organization1)
    assert_equal(organization1.name, 'organization-member-import1')
    assert_equal(organization1.members.count, 0)
    organization2 = Organization.find_by(name: 'organization-member-import2')
    assert(organization2)
    assert_equal(organization2.name, 'organization-member-import2')
    assert_equal(organization2.members.count, 2)

    customer1.destroy!
    customer2.destroy!
    organization1.destroy!
    organization2.destroy!
  end

  test 'invalid attributes' do

    csv_string = "name;note;not existing\norganization-invalid-import1;some note;abc\norganization-invalid-import2;some other note;123; with not exsiting header\n"
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: Unable to create record - unknown attribute 'not existing' for Organization.", result[:errors][0])
    assert_equal("Line 2: Unable to create record - unknown attribute 'not existing' for Organization.", result[:errors][1])

    assert_nil(Organization.find_by(name: 'organization-invalid-import1'))
    assert_nil(Organization.find_by(name: 'organization-invalid-import2'))

    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )
    assert_equal(false, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: Unable to create record - unknown attribute 'not existing' for Organization.", result[:errors][0])
    assert_equal("Line 2: Unable to create record - unknown attribute 'not existing' for Organization.", result[:errors][1])

    assert_nil(Organization.find_by(name: 'organization-invalid-import1'))
    assert_nil(Organization.find_by(name: 'organization-invalid-import2'))
  end

  test 'simple import with delete' do
    csv_string = "id;name;shared;domain;domain_assignment;active;note\n;org-simple-import1;true;org-simple-import1.example.com;false;true;some note1\n;org-simple-import2;true;org-simple-import2.example.com;false;false;some note2\n"
    result = Organization.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
      delete:       true,
    )

    assert_equal(true, result[:try])
    assert_equal('failed', result[:result])
    assert_equal('Delete is not possible for Organization.', result[:errors][0])
  end

end
