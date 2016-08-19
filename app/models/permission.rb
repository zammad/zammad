# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Permission < ApplicationModel
  has_and_belongs_to_many :roles
  validates               :name, presence: true
  store                   :preferences
  notify_clients_support
  latest_change_support

=begin

  permissions = Permission.with_parents('some_key.sub_key')

returnes

  ['some_key.sub_key', 'some_key']

=end

  def self.with_parents(key)
    names = []
    part = ''
    key.split('.').each { |local_part|
      if part != ''
        part += '.'
      end
      part += local_part
      names.push part
    }
    names
  end

end
