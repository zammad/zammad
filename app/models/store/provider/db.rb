# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store::Provider::DB < ApplicationModel
  self.table_name = 'store_provider_dbs'

  def self.add(data, md5)
    Store::Provider::DB.create(
      :data => data,
      :md5  => md5,
    )
    true
  end

  def self.get(md5)
    file = Store::Provider::DB.where( :md5 => md5 ).first
    return if !file
    file.data
  end

  def self.delete(md5)
    Store::Provider::DB.where( :md5 => md5 ).destroy_all
    true
  end

end