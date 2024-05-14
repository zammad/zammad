# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Permission < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasCollectionUpdate

  has_and_belongs_to_many :roles
  store                   :preferences

  validates :name, presence: true

  # This is added to handle migrations from before the columns were modified.
  # For example when upgrading from pre-6.4.
  # Otherwise older migrations fail since those columnsa are not yet available.
  with_options if: -> { respond_to?(:label) && respond_to?(:description) } do
    validates :label, length: { maximum: 255 }
    validates :description, length: { maximum: 500 }
  end

  sanitized_html :description

  # Returns permission name with parent permission names
  #
  # @return [String]
  #
  # @example
  #   Permission.with_parents('some_key.sub_key')
  #   #=> ['some_key.sub_key', 'some_key']
  def self.with_parents(key)
    key
      .split('.')
      .each_with_object([]) do |elem, memo|
        memo << if (previous = memo.last)
                  "#{previous}.#{elem}"
                else
                  elem
                end
      end
  end

  def to_s
    name
  end

  def self.join_with(object, permissions)
    return object if !object.method_defined?(:permissions?)

    permissions = with_parents(permissions)

    object
      .joins(roles: :permissions)
      .where(roles: { active: true }, permissions: { name: permissions, active: true })
  end
end
