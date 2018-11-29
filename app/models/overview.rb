# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Overview < ApplicationModel
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include ChecksConditionValidation
  include CanSeed

  include Overview::Assets

  has_and_belongs_to_many :roles, after_add: :cache_update, after_remove: :cache_update, class_name: 'Role'
  has_and_belongs_to_many :users, after_add: :cache_update, after_remove: :cache_update, class_name: 'User'
  store     :condition
  store     :order
  store     :view
  validates :name, presence: true
  validates :roles, presence: true

  before_create :fill_link_on_create, :fill_prio
  before_update :fill_link_on_update, :rearrangement

  private

  def rearrangement
    return true if !changes['prio']
    prio = 0
    Overview.all.order(prio: :asc, updated_at: :desc).pluck(:id).each do |overview_id|
      prio += 1
      next if id == overview_id
      Overview.without_callback(:update, :before, :rearrangement) do
        overview = Overview.find(overview_id)
        next if overview.prio == prio
        overview.prio = prio
        overview.save!
      end
    end
  end

  def fill_prio
    return true if prio.present?
    self.prio = Overview.count + 1
    true
  end

  def fill_link_on_create
    self.link = if link.present?
                  link_name(link)
                else
                  link_name(name)
                end
    true
  end

  def fill_link_on_update
    return true if !changes['name'] && !changes['link']
    self.link = if link.present?
                  link_name(link)
                else
                  link_name(name)
                end
    true
  end

  def link_name(name)
    local_link = name.downcase
    local_link = local_link.parameterize(separator: '_')
    local_link.gsub!(/\s/, '_')
    local_link.gsub!(/_+/, '_')
    local_link = CGI.escape(local_link)
    if local_link.blank?
      local_link = id || rand(999)
    end
    check = true
    count = 0
    local_lookup_link = local_link
    while check
      count += 1
      exists = Overview.find_by(link: local_lookup_link)
      if exists && exists.id != id
        local_lookup_link = "#{local_link}_#{count}"
      else
        check = false
        local_link = local_lookup_link
      end
    end
    local_link
  end

end
