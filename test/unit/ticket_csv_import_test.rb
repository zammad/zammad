# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TicketCsvImportTest < ActiveSupport::TestCase

  test 'import example verify' do
    csv_string = Ticket.csv_example

    rows = CSV.parse(csv_string)
    header = rows.shift
    assert_equal('id', header[0])
    assert_equal('number', header[1])
    assert_equal('title', header[2])
    assert_equal('note', header[3])
    assert_equal('first_response_at', header[4])
    assert_equal('first_response_escalation_at', header[5])
    assert(header.include?('organization'))
    assert(header.include?('priority'))
    assert(header.include?('state'))
    assert(header.include?('owner'))
    assert(header.include?('customer'))

  end

  test 'empty payload' do
    csv_string = ''
    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_nil(result[:records])
    assert_equal('failed', result[:result])
    assert_equal('Unable to parse empty file/string for Ticket.', result[:errors][0])

    csv_string = 'id;number;title;state;priority;'
    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert(result[:records].blank?)
    assert_equal('failed', result[:result])
    assert_equal('No records found in file/string for Ticket.', result[:errors][0])
  end

  test 'verify required lookup headers' do
    csv_string = "firstname;lastname;active;\nfirstname-simple-import1;lastname-simple-import1;;true\nfirstname-simple-import2;lastname-simple-import2;false\n"
    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal('failed', result[:result])
    assert_equal('No lookup column like id,number for Ticket found.', result[:errors][0])
  end

  test 'simple import' do

    csv_string = "id;number;title;state;priority;owner;customer;group;note\n;123456;some title1;new;2 normal;-;nicole.braun@zammad.org;Users;some note1\n;123457;some title2;closed;1 low;admin@example.com;nicole.braun@zammad.org;Users;some note2\n"
    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(Ticket.find_by(number: '123456'))
    assert_nil(Ticket.find_by(number: '123457'))

    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )

    assert_equal(false, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    ticket1 = Ticket.find_by(number: '123456')
    assert(ticket1)
    assert_equal(ticket1.number, '123456')
    assert_equal(ticket1.title, 'some title1')
    assert_equal(ticket1.state.name, 'new')
    assert_equal(ticket1.priority.name, '2 normal')
    assert_equal(ticket1.owner.login, '-')
    assert_equal(ticket1.customer.login, 'nicole.braun@zammad.org')
    assert_equal(ticket1.note, 'some note1')
    ticket2 = Ticket.find_by(number: '123457')
    assert(ticket2)
    assert_equal(ticket2.number, '123457')
    assert_equal(ticket2.title, 'some title2')
    assert_equal(ticket2.state.name, 'closed')
    assert_equal(ticket2.priority.name, '1 low')
    assert_equal(ticket2.owner.login, 'admin@example.com')
    assert_equal(ticket2.customer.login, 'nicole.braun@zammad.org')
    assert_equal(ticket2.note, 'some note2')

    ticket1.destroy!
    ticket2.destroy!
  end

  test 'simple import with invalid id' do

    csv_string = "id;number;title;state;priority;owner;customer;group;note\n999999999;123456;some title1;new;2 normal;-;nicole.braun@zammad.org;Users;some note1\n;123457;some title2;closed;1 low;admin@example.com;nicole.braun@zammad.org;Users;some note2\n"
    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal(1, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: unknown Ticket with id '999999999'.", result[:errors][0])

    assert_nil(Ticket.find_by(number: '123456'))
    assert_nil(Ticket.find_by(number: '123457'))

    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )
    assert_equal(false, result[:try])
    assert_equal(1, result[:records].count)
    assert_equal('failed', result[:result])

    assert_nil(Ticket.find_by(number: '123456'))

    # any single failure will cause the entire import to be aborted
    assert_nil(Ticket.find_by(number: '123457'))

    csv_string = "id;number;title;state;priority;owner;customer;group;note\n999999999;123456;some title1;new;2 normal;-;nicole.braun@zammad.org;Users;some note1\n;123457;some title22;closed;1 low;admin@example.com;nicole.braun@zammad.org;Users;some note22\n"

    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )
    assert_equal(false, result[:try])
    assert_equal(1, result[:records].count)
    assert_equal('failed', result[:result])

    assert_nil(Ticket.find_by(number: '123456'))

    # any single failure will cause the entire import to be aborted
    assert_nil(Ticket.find_by(number: '123457'))
  end

  test 'invalid attributes' do

    csv_string = "id;number;not_existing;state;priority;owner;customer;group;note\n;123456;some title1;new;2 normal;-;nicole.braun@zammad.org;Users;some note1\n;123457;some title2;closed;1 low;admin@example.com;nicole.braun@zammad.org;Users;some note2\n"
    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: Unable to create record - unknown attribute 'not_existing' for Ticket.", result[:errors][0])
    assert_equal("Line 2: Unable to create record - unknown attribute 'not_existing' for Ticket.", result[:errors][1])

    assert_nil(Ticket.find_by(number: '123456'))
    assert_nil(Ticket.find_by(number: '123457'))

    result = Ticket.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )
    assert_equal(false, result[:try])
    assert_equal(2, result[:errors].count)
    assert_equal('failed', result[:result])
    assert_equal("Line 1: Unable to create record - unknown attribute 'not_existing' for Ticket.", result[:errors][0])
    assert_equal("Line 2: Unable to create record - unknown attribute 'not_existing' for Ticket.", result[:errors][1])

    assert_nil(Ticket.find_by(number: '123456'))
    assert_nil(Ticket.find_by(number: '123457'))
  end

end
