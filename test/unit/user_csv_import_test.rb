
require 'test_helper'

class UserCsvImportTest < ActiveSupport::TestCase

  test 'import example verify' do
    csv_string = User.csv_example

    rows = CSV.parse(csv_string)
    header = rows.shift

    assert_equal('id', header[0])
    assert_equal('login', header[1])
    assert_equal('firstname', header[2])
    assert_equal('lastname', header[3])
    assert_equal('email', header[4])
    assert(header.include?('organization'))
  end

  test 'empty payload' do
    csv_string = ''
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_nil(result[:records])
    assert_equal('failed', result[:result])
    assert_equal('Unable to parse empty file/string for User.', result[:errors][0])

    csv_string = "login;firstname;lastname;email;active;\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert(result[:records].blank?)
    assert_equal('failed', result[:result])
    assert_equal('No records found in file/string for User.', result[:errors][0])
  end

  test 'simple import' do

    csv_string = "login;firstname;lastname;email;active;\nuser-simple-import1;firstname-simple-import1;lastname-simple-import1;user-simple-import1@example.com;true\nuser-simple-import2;firstname-simple-import2;lastname-simple-import2;user-simple-import2@example.com;false\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(User.find_by(login: 'user-simple-import1'))
    assert_nil(User.find_by(login: 'user-simple-import2'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    user1 = User.find_by(login: 'user-simple-import1')
    assert(user1)
    assert_equal(user1.login, 'user-simple-import1')
    assert_equal(user1.firstname, 'firstname-simple-import1')
    assert_equal(user1.lastname, 'lastname-simple-import1')
    assert_equal(user1.email, 'user-simple-import1@example.com')
    assert_equal(user1.active, true)
    user2 = User.find_by(login: 'user-simple-import2')
    assert(user2)
    assert_equal(user2.login, 'user-simple-import2')
    assert_equal(user2.firstname, 'firstname-simple-import2')
    assert_equal(user2.lastname, 'lastname-simple-import2')
    assert_equal(user2.email, 'user-simple-import2@example.com')
    assert_equal(user2.active, false)

    user1.destroy!
    user2.destroy!
  end

  test 'simple import with invalid id' do

    csv_string = "id;login;firstname;lastname;email;active;\n999999999;user-simple-invalid_id-import1;firstname-simple-import1;lastname-simple-import1;user-simple-invalid_id-import1@example.com;true\n;user-simple-invalid_id-import2;firstname-simple-import2;lastname-simple-import2;user-simple-invalid_id-import2@example.com;false\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(1, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: unknown record with id '999999999' for User.", result[:errors][0])

    assert_nil(User.find_by(login: 'user-simple-invalid_id-import1'))
    assert_nil(User.find_by(login: 'user-simple-invalid_id-import2'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(1, result[:records].count)
    assert_equal('failed', result[:result])

    assert_nil(User.find_by(login: 'user-simple-invalid_id-import1'))

    user2 = User.find_by(login: 'user-simple-invalid_id-import2')
    assert(user2)
    assert_equal(user2.login, 'user-simple-invalid_id-import2')
    assert_equal(user2.firstname, 'firstname-simple-import2')
    assert_equal(user2.lastname, 'lastname-simple-import2')
    assert_equal(user2.email, 'user-simple-invalid_id-import2@example.com')
    assert_equal(user2.active, false)

    user2.destroy!
  end

  test 'simple import with read only id' do

    csv_string = "id;login;firstname;lastname;email;active;\n1;user-simple-readonly_id-import1;firstname-simple-import1;lastname-simple-import1;user-simple-readonly_id-import1@example.com;true\n;user-simple-readonly_id-import2;firstname-simple-import2;lastname-simple-import2;user-simple-readonly_id-import2@example.com;false\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(1, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: unable to update record with id '1' for User.", result[:errors][0])

    assert_nil(User.find_by(login: 'user-simple-readonly_id-import1'))
    assert_nil(User.find_by(login: 'user-simple-readonly_id-import2'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(1, result[:records].count)
    assert_equal('failed', result[:result])

    assert_nil(User.find_by(login: 'user-simple-readonly_id-import1'))

    user2 = User.find_by(login: 'user-simple-readonly_id-import2')
    assert(user2)
    assert_equal(user2.login, 'user-simple-readonly_id-import2')
    assert_equal(user2.firstname, 'firstname-simple-import2')
    assert_equal(user2.lastname, 'lastname-simple-import2')
    assert_equal(user2.email, 'user-simple-readonly_id-import2@example.com')
    assert_equal(user2.active, false)

    user2.destroy!
  end

  test 'simple import with roles' do
    UserInfo.current_user_id = 1

    admin = User.create_or_update(
      login: 'admin1@example.com',
      firstname: 'Admin',
      lastname: '1',
      email: 'admin1@example.com',
      password: 'agentpw',
      active: true,
      roles: Role.where(name: 'Admin'),
    )

    csv_string = "login;firstname;lastname;email;roles;\nuser-role-import1;firstname-role-import1;lastname-role-import1;user-role-import1@example.com;Customer;\nuser-role-import2;firstname-role-import2;lastname-role-import2;user-role-import2@example.com;Agent\n;;;;Admin"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )

    assert_equal(true, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(User.find_by(login: 'user-role-import1'))
    assert_nil(User.find_by(login: 'user-role-import2'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )

    assert_equal(false, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    user1 = User.find_by(login: 'user-role-import1')
    assert(user1)
    assert_equal(user1.login, 'user-role-import1')
    assert_equal(user1.firstname, 'firstname-role-import1')
    assert_equal(user1.lastname, 'lastname-role-import1')
    assert_equal(user1.email, 'user-role-import1@example.com')
    assert_equal(user1.roles.count, 1)
    user2 = User.find_by(login: 'user-role-import2')
    assert(user2)
    assert_equal(user2.login, 'user-role-import2')
    assert_equal(user2.firstname, 'firstname-role-import2')
    assert_equal(user2.lastname, 'lastname-role-import2')
    assert_equal(user2.email, 'user-role-import2@example.com')
    assert_equal(user2.roles.count, 2)

    user1.destroy!
    user2.destroy!
    admin.destroy!
  end

  test 'simple import + fixed params' do

    csv_string = "login;firstname;lastname;email\nuser-simple-import-fixed1;firstname-simple-import-fixed1;lastname-simple-import-fixed1;user-simple-import-fixed1@example.com\nuser-simple-import-fixed2;firstname-simple-import-fixed2;lastname-simple-import-fixed2;user-simple-import-fixed2@example.com\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      fixed_params: {
        note: 'some note',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(User.find_by(login: 'user-simple-import-fixed1'))
    assert_nil(User.find_by(login: 'user-simple-import-fixed2'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      fixed_params: {
        note: 'some note',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    user1 = User.find_by(login: 'user-simple-import-fixed1')
    user2 = User.find_by(login: 'user-simple-import-fixed2')
    assert(user1)
    assert_equal('some note', user1.note)
    assert_equal('user-simple-import-fixed1', user1.login)
    assert_equal('firstname-simple-import-fixed1', user1.firstname)
    assert_equal('lastname-simple-import-fixed1', user1.lastname)
    assert_equal('user-simple-import-fixed1@example.com', user1.email)

    assert(user2)
    assert_equal('some note', user2.note)
    assert_equal('user-simple-import-fixed2', user2.login)
    assert_equal('firstname-simple-import-fixed2', user2.firstname)
    assert_equal('lastname-simple-import-fixed2', user2.lastname)
    assert_equal('user-simple-import-fixed2@example.com', user2.email)

    user1.destroy!
    user2.destroy!
  end

  test 'duplicate import' do

    csv_string = "login;firstname;lastname;email\nuser-duplicate-import1;firstname-duplicate-import1;firstname-duplicate-import1;user-duplicate-import1@example.com\nuser-duplicate-import2;firstname-duplicate-import2;firstname-duplicate-import2;user-duplicate-import2@example.com\nuser-duplicate-import2;firstname-duplicate-import3;firstname-duplicate-import3;user-duplicate-import3@example.com"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(3, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(User.find_by(login: 'user-duplicate-import1'))
    assert_nil(User.find_by(login: 'user-duplicate-import2'))
    assert_nil(User.find_by(login: 'user-duplicate-import3'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(3, result[:records].count)
    assert_equal('success', result[:result])

    assert(User.find_by(login: 'user-duplicate-import1'))
    assert(User.find_by(login: 'user-duplicate-import2'))
    assert_nil(User.find_by(login: 'user-duplicate-import3'))

    User.find_by(login: 'user-duplicate-import1').destroy!
    User.find_by(login: 'user-duplicate-import2').destroy!
  end

  test 'invalid attributes' do

    csv_string = "login;firstname2;lastname;email\nuser-invalid-import1;firstname-invalid-import1;firstname-invalid-import1;user-invalid-import1@example.com\nuser-invalid-import2;firstname-invalid-import2;firstname-invalid-import2;user-invalid-import2@example.com\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: unknown attribute 'firstname2' for User.", result[:errors][0])
    assert_equal("Line 2: unknown attribute 'firstname2' for User.", result[:errors][1])

    assert_nil(User.find_by(login: 'user-invalid-import1'))
    assert_nil(User.find_by(login: 'user-invalid-import2'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: unknown attribute 'firstname2' for User.", result[:errors][0])
    assert_equal("Line 2: unknown attribute 'firstname2' for User.", result[:errors][1])

    assert_nil(User.find_by(login: 'user-invalid-import1'))
    assert_nil(User.find_by(login: 'user-invalid-import2'))
  end

  test 'reference import' do

    csv_string = "login;firstname;lastname;email;organization\nuser-reference-import1;firstname-reference-import1;firstname-reference-import1;user-reference-import1@example.com;organization-reference-import1\nuser-reference-import2;firstname-reference-import2;firstname-reference-import2;user-reference-import2@example.com;organization-reference-import2\nuser-reference-import3;firstname-reference-import3;firstname-reference-import3;user-reference-import3@example.com;Zammad Foundation\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_nil(User.find_by(login: 'user-reference-import1'))
    assert_nil(User.find_by(login: 'user-reference-import2'))
    assert_nil(User.find_by(login: 'user-reference-import3'))
    assert_equal("Line 1: No lookup value found for 'organization': \"organization-reference-import1\"", result[:errors][0])
    assert_equal("Line 2: No lookup value found for 'organization': \"organization-reference-import2\"", result[:errors][1])

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])

    assert_nil(User.find_by(login: 'user-reference-import1'))
    assert_nil(User.find_by(login: 'user-reference-import2'))
    assert(User.find_by(login: 'user-reference-import3'))
    assert_equal("Line 1: No lookup value found for 'organization': \"organization-reference-import1\"", result[:errors][0])
    assert_equal("Line 2: No lookup value found for 'organization': \"organization-reference-import2\"", result[:errors][1])

    UserInfo.current_user_id = 1
    orgaization1 = Organization.create_if_not_exists(name: 'organization-reference-import1')
    orgaization2 = Organization.create_if_not_exists(name: 'organization-reference-import2')

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
    )
    assert_equal(true, result[:try])
    assert_equal(0, result[:errors].count)
    assert_equal('success', result[:result])
    assert_nil(User.find_by(login: 'user-reference-import1'))
    assert_nil(User.find_by(login: 'user-reference-import2'))
    assert(User.find_by(login: 'user-reference-import3'))

    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: false,
    )
    assert_equal(false, result[:try])
    assert_equal(0, result[:errors].count)
    assert_equal('success', result[:result])

    assert(User.find_by(login: 'user-reference-import1'))
    assert(User.find_by(login: 'user-reference-import2'))
    assert(User.find_by(login: 'user-reference-import3'))

    User.find_by(login: 'user-reference-import1').destroy!
    User.find_by(login: 'user-reference-import2').destroy!
    User.find_by(login: 'user-reference-import3').destroy!

    orgaization1.destroy!
    orgaization2.destroy!
  end

  test 'simple import with delete' do
    csv_string = "login;firstname;lastname;email\nuser-simple-import-fixed1;firstname-simple-import-fixed1;lastname-simple-import-fixed1;user-simple-import-fixed1@example.com\nuser-simple-import-fixed2;firstname-simple-import-fixed2;lastname-simple-import-fixed2;user-simple-import-fixed2@example.com\n"
    result = User.csv_import(
      string: csv_string,
      parse_params: {
        col_sep: ';',
      },
      try: true,
      delete: true,
    )

    assert_equal(true, result[:try])
    assert_equal('failed', result[:result])
    assert_equal('Delete is not possible for User.', result[:errors][0])
  end

end
