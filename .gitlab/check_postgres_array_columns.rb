#!/usr/bin/env ruby
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require File.expand_path('../config/environment', __dir__)

class CheckPostgresArrayColumns
  def self.run
    puts 'Checking database array columns:'

    check_columns_type
    check_columns_array

    puts 'done.'
  end

  def self.check_columns_type
    puts '  (type == :string):'

    table_information.each do |item|
      print "    #{item[:table]}.#{item[:column]} ... "

      type = column(item[:table], item[:column]).type

      if type == :string
        puts 'OK'
      else
        puts 'Not OK!'
        puts "    Expected type :string, but got: #{type}"
        exit 1
      end
    end
  end

  def self.check_columns_array
    puts '  (array == true):'

    table_information.each do |item|
      print "    #{item[:table]}.#{item[:column]} ... "

      array = column(item[:table], item[:column]).array

      if array
        puts 'OK'
      else
        puts 'Not OK!'
        puts "      Expected array true, but got: #{array}"
        exit 1
      end
    end
  end

  def self.object_manager_attributes
    ObjectManager::Attribute.where(data_type: %w[multiselect multi_tree_select]).map do |field|
      { table: field.object_lookup.name.constantize.table_name, column: field.name }
    end
  end

  def self.smime_certificates
    [{ table: SMIMECertificate.table_name, column: 'email_addresses' }]
  end

  def self.pgp_keys
    [{ table: PGPKey.table_name, column: 'email_addresses' }]
  end

  def self.public_links
    [{ table: PublicLink.table_name, column: 'screen' }]
  end

  def self.checklists
    [{ table: Checklist.table_name, column: 'sorted_item_ids' }]
  end

  def self.checklist_templates
    [{ table: ChecklistTemplate.table_name, column: 'sorted_item_ids' }]
  end

  def self.table_information
    smime_certificates + pgp_keys + public_links + checklists + checklist_templates + object_manager_attributes
  end

  def self.column(table, column)
    ActiveRecord::Base.connection.columns(table.to_sym).find { |c| c.name == column }
  end
end

CheckPostgresArrayColumns.run
