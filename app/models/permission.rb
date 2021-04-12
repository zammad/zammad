# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Permission < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include ChecksLatestChangeObserved
  include HasCollectionUpdate

  has_and_belongs_to_many :roles
  validates               :name, presence: true
  store                   :preferences

  sanitized_html :note

=begin

  permissions = Permission.with_parents('some_key.sub_key')

returns

  ['some_key.sub_key', 'some_key']

=end

  def self.with_parents(key)
    names = []
    part = ''
    key.split('.').each do |local_part|
      if part != ''
        part += '.'
      end
      part += local_part
      names.push part
    end
    names
  end

  def to_s
    name
  end

end
