#!/usr/bin/env ruby
# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require File.expand_path('../config/environment', __dir__)

class CheckPostgresArrayColumns
  def self.run
    if Rails.configuration.database_configuration[Rails.env]['adapter'] != 'postgresql'
      puts 'Error: This script works only with postgresql adapter!'
      exit 1
    end

    puts 'Checking data type of array columns:'

    check_columns

    puts 'done.'
  end

  def self.check_columns
    public_links.concat(object_manager_attributes).each do |item|
      print "  #{item[:table]}.#{item[:column]} ... "

      type = data_type(item[:table], item[:column])

      if type == 'ARRAY'
        puts 'OK'
      else
        puts 'Not OK!'
        puts "    Expected type ARRAY, but got: #{type}"
        exit 1
      end
    end
  end

  def self.object_manager_attributes
    ObjectManager::Attribute.where(data_type: %w[multiselect multi_tree_select]).map do |field|
      { table: field.object_lookup.name.constantize.table_name, column: field.name }
    end
  end

  def self.public_links
    [{ table: PublicLink.table_name, column: 'screen' }]
  end

  def self.data_type(table, column)
    ActiveRecord::Base.connection.execute("select data_type from information_schema.columns where table_name = '#{table}' and column_name = '#{column}' limit 1")[0]['data_type']
  end
end

CheckPostgresArrayColumns.run
