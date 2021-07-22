# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

# https://github.com/zammad/zammad/issues/266
RSpec.describe 'Admin Panel > Objects', type: :system do
  before do
    visit '/#system/object_manager'
  end

  it 'verifies option creation order of new tree select options' do

    # create new field
    page.find('.js-new').click

    # set meta information
    fill_in 'Name', with: 'tree1'
    fill_in 'Display', with: 'tree1'
    page.find('select[name=data_type]').select('Tree Select')

    # create 3 childs
    first_add_child = page.first('div.js-addChild')
    first_add_child.click
    first_add_child.click
    first_add_child.click

    # create 1 top level node sibling
    page.first('div.js-addRow').click

    # create 3 childs for the new top level node
    page.all('div.js-addChild').last.click
    page.all('div.js-addChild').last.click
    page.all('div.js-addChild').last.click

    # create new top level nodes by first and second top level node
    add_rows = page.all('div.js-addRow')
    add_rows[0].click
    add_rows[4].click

    # add numbers to all inputs to verify order in config later
    number = 1
    page.all('input.js-key').each do |input|
      input.send_keys(number)
      number += 1
    end

    page.find('.js-submit').click
    expected_data_options = { 'options'    =>
                                              [{ 'name'     => '1',
                                                 'value'    => '1',
                                                 'children' => [{ 'name' => '2', 'value' => '1::2' }, { 'name' => '3', 'value' => '1::3' }, { 'name' => '4', 'value' => '1::4' }] },
                                               { 'name' => '5', 'value' => '5' },
                                               { 'name'     => '6',
                                                 'value'    => '6',
                                                 'children' =>
                                                               [{ 'name'     => '7',
                                                                  'value'    => '6::7',
                                                                  'children' => [{ 'name' => '8', 'value' => '6::7::8', 'children' => [{ 'name' => '9', 'value' => '6::7::8::9' }] }] }] },
                                               { 'name' => '10', 'value' => '10' }],
                              'default'    => '',
                              'null'       => true,
                              'relation'   => '',
                              'nulloption' => true,
                              'maxlength'  => 255 }

    expect(ObjectManager::Attribute.last.data_option).to eq(expected_data_options)
  end

  it 'checks smart defaults for select field' do
    page.find('.js-new').click

    fill_in 'Name', with: 'select1'
    find('input[name=display]').set('select1')

    page.find('select[name=data_type]').select('Select')

    page.first('div.js-add').click
    page.first('div.js-add').click
    page.first('div.js-add').click

    counter = 0
    page.all('.js-key').each do |field|
      field.set(counter)
      counter += 1
    end

    page.all('.js-value')[-2].set('special 2')
    page.find('.js-submit').click

    expected_data_options = {
      '0' => '0',
      '1' => '1',
      '2' => 'special 2',
    }

    expect(ObjectManager::Attribute.last.data_option['options']).to eq(expected_data_options)
  end

  it 'checks smart defaults for boolean field' do
    page.find('.js-new').click

    fill_in 'Name', with: 'bool1'
    find('input[name=display]').set('bool1')

    page.find('select[name=data_type]').select('Boolean')
    page.find('.js-valueFalse').set('HELL NOO')
    page.find('.js-submit').click

    expected_data_options = {
      true  => 'yes',
      false => 'HELL NOO',
    }

    expect(ObjectManager::Attribute.last.data_option['options']).to eq(expected_data_options)
  end
end
