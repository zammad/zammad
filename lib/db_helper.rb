# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DbHelper

=begin

execute post database statements after import (e. g. reset primary key sequences for postgresql)

  DbHelper.import_post

or only for certain tables

  DbHelper.import_post(table_name)

=end

  def self.import_post(table = nil)
    return if ActiveRecord::Base.connection_config[:adapter] != 'postgresql'

    tables = if table
               [table]
             else
               ActiveRecord::Base.connection.tables
             end

    tables.each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end
  end

end
