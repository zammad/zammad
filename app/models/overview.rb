# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Overview < ApplicationModel
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include ChecksConditionValidation
  include CanSeed

  load 'overview/assets.rb'
  include Overview::Assets

  has_and_belongs_to_many :roles, after_add: :cache_update, after_remove: :cache_update, class_name: 'Role'
  has_and_belongs_to_many :users, after_add: :cache_update, after_remove: :cache_update
  store     :condition
  store     :order
  store     :view
  validates :name, presence: true

  before_create :fill_link_on_create, :fill_prio
  before_update :fill_link_on_update

  private

  def fill_prio
    return true if prio
    self.prio = 9999
    true
  end

  def fill_link_on_create
    return true if link.present?
    self.link = link_name(name)
    true
  end

  def fill_link_on_update
    return true if !changes['name']
    return true if changes['link']
    self.link = link_name(name)
    true
  end

  def link_name(name)
    local_link = name.downcase
    local_link = local_link.parameterize('_')
    local_link.gsub!(/\s/, '_')
    local_link.gsub!(/_+/, '_')
    local_link = URI.escape(local_link)
    if local_link.blank?
      local_link = id || rand(999)
    end
    check = true
    while check
      exists = Overview.find_by(link: local_link)
      if exists && exists.id != id
        local_link = "#{local_link}_#{rand(999)}"
      else
        check = false
      end
    end
    local_link
  end

end
