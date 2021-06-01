# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'test_helper'

class TextModuleCsvImportTest < ActiveSupport::TestCase

  test 'import example verify' do
    TextModule.load('en-en')
    csv_string = TextModule.csv_example

    rows = CSV.parse(csv_string)
    header = rows.shift
    assert_equal('id', header[0])
    assert_equal('name', header[1])
    assert_equal('keywords', header[2])
    assert_equal('content', header[3])
    assert_equal('note', header[4])
    assert_equal('active', header[5])
    assert_not(header.include?('organization'))
    assert_not(header.include?('priority'))
    assert_not(header.include?('state'))
    assert_not(header.include?('owner'))
    assert_not(header.include?('customer'))
  end

  test 'empty payload' do
    csv_string = ''
    result = TextModule.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_nil(result[:records])
    assert_equal('failed', result[:result])
    assert_equal('Unable to parse empty file/string for TextModule.', result[:errors][0])

    csv_string = 'name;keywords;content;note;active;'
    result = TextModule.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert(result[:records].blank?)
    assert_equal('failed', result[:result])
    assert_equal('No records found in file/string for TextModule.', result[:errors][0])
  end

  test 'verify required lookup headers' do
    csv_string = "firstname;lastname;active;\nfirstname-simple-import1;lastname-simple-import1;;true\nfirstname-simple-import2;lastname-simple-import2;false\n"
    result = TextModule.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )
    assert_equal(true, result[:try])
    assert_equal('failed', result[:result])
    assert_equal('No lookup column like id,name for TextModule found.', result[:errors][0])
  end

  test 'simple import' do
    TextModule.create!(
      name:          'nsome name1',
      content:       'nsome name1',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    csv_string = "name;keywords;content;note;active;\nsome name1;keyword1;\"some\ncontent1\";-;\nsome name2;keyword2;some content<br>test123\n"
    result = TextModule.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
    )

    assert_equal(true, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_nil(TextModule.find_by(name: 'some name1'))
    assert_nil(TextModule.find_by(name: 'some name2'))

    result = TextModule.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
    )

    assert_equal(false, result[:try])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    text_module1 = TextModule.find_by(name: 'some name1')
    assert(text_module1)
    assert_equal(text_module1.name, 'some name1')
    assert_equal(text_module1.keywords, 'keyword1')
    assert_equal(text_module1.content, 'some<br>content1')
    assert_equal(text_module1.active, true)
    text_module2 = TextModule.find_by(name: 'some name2')
    assert(text_module2)
    assert_equal(text_module2.name, 'some name2')
    assert_equal(text_module2.keywords, 'keyword2')
    assert_equal(text_module2.content, 'some content<br>test123')
    assert_equal(text_module2.active, true)

    text_module1.destroy!
    text_module2.destroy!
  end

  test 'simple import with delete' do
    assert_equal(0, TextModule.count)

    TextModule.create!(
      name:          'some name1',
      content:       'some name1',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    TextModule.create!(
      name:          'name should be deleted 2',
      content:       'name should be deleted 1',
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    csv_string = "name;keywords;content;note;active;\nsome name1;keyword1;\"some\ncontent1\";-;\nsome name2;keyword2;some content<br>test123\n"
    result = TextModule.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          true,
      delete:       true,
    )

    assert_equal(true, result[:try])
    assert(result[:stats])
    assert_equal(2, result[:stats][:created])
    assert_equal(0, result[:stats][:updated])
    assert_equal(2, result[:stats][:deleted])

    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert(TextModule.find_by(name: 'some name1'))
    assert_nil(TextModule.find_by(name: 'some name2'))

    result = TextModule.csv_import(
      string:       csv_string,
      parse_params: {
        col_sep: ';',
      },
      try:          false,
      delete:       true,
    )

    assert_equal(false, result[:try])
    assert(result[:stats])
    assert_equal(2, result[:stats][:created])
    assert_equal(0, result[:stats][:updated])
    assert_equal(2, result[:stats][:deleted])
    assert_equal(2, result[:records].count)
    assert_equal('success', result[:result])

    assert_equal(2, TextModule.count)

    text_module1 = TextModule.find_by(name: 'some name1')
    assert(text_module1)
    assert_equal(text_module1.name, 'some name1')
    assert_equal(text_module1.keywords, 'keyword1')
    assert_equal(text_module1.content, 'some<br>content1')
    assert_equal(text_module1.active, true)
    text_module2 = TextModule.find_by(name: 'some name2')
    assert(text_module2)
    assert_equal(text_module2.name, 'some name2')
    assert_equal(text_module2.keywords, 'keyword2')
    assert_equal(text_module2.content, 'some content<br>test123')
    assert_equal(text_module2.active, true)

    assert_nil(TextModule.find_by(name: 'name should be deleted 2'))

    text_module1.destroy!
    text_module2.destroy!
  end

end
