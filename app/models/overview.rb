# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

  def self.calculate_prio
    existing_maximum = Overview.maximum(:prio)

    return 0 if !existing_maximum

    existing_maximum + 1
  end

  private

  def rearrangement
    # rearrange only in case of changed prio
    return true if !changes['prio']

    previous_ordered_ids = self.class.all.order(
      prio:       :asc,
      updated_at: :desc
    ).pluck(:id)

    rearranged_prio = 0
    previous_ordered_ids.each do |overview_id|

      # don't process currently updated overview
      next if id == overview_id

      rearranged_prio += 1

      # increase rearranged prio by one to avoid a collition
      # with the changed prio of current instance
      if rearranged_prio == prio
        rearranged_prio += 1
      end

      # don't start rearranging logic for overviews that have already been rearranged
      self.class.without_callback(:update, :before, :rearrangement) do
        # fetch and update overview only if prio needs to change
        overview = self.class.where(
          id: overview_id
        ).where.not(
          prio: rearranged_prio
        ).take

        next if overview.blank?

        overview.update!(prio: rearranged_prio)
      end
    end
  end

  def fill_prio
    return true if prio.present?

    self.prio = self.class.calculate_prio
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
    local_link.gsub!(%r{\s}, '_')
    local_link.squeeze!('_')
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
