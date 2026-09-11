# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UserInfo::Assets
  LEVEL_CUSTOMER = 1
  LEVEL_AGENT    = 2
  LEVEL_ADMIN    = 3

  attr_accessor :current_user_id, :level, :filter_attributes, :user

  # Returns the assets level a user is rendered at, or nil for no user.
  def self.level_for(user)
    return if user.blank?

    level = LEVEL_CUSTOMER
    user.permissions_with_child_names.each do |permission|
      return LEVEL_ADMIN if permission.match?(%r{^admin\.})

      level = LEVEL_AGENT if permission == 'ticket.agent'
    end

    level
  end

  # The levels of many users at once, as a Hash of user id to level. Ids of users that do not
  #   exist are absent from it, so it doubles as the existence check a caller needs anyway.
  #
  # A level is decided by the permissions of a user's active roles - #permissions is a
  #   has_many :through of exactly those - so users who share a role set share a level. This
  #   resolves one user per distinct role set instead of one per user, which is the difference
  #   between three queries per session and three queries per instance for a broadcast.
  def self.levels_for(user_ids)
    user_ids = Array(user_ids).compact.uniq
    return {} if user_ids.blank?

    existing_ids = User.where(id: user_ids).pluck(:id)
    return {} if existing_ids.blank?

    role_sets = role_sets_for(existing_ids)

    # one user id per distinct role set, so #level_for runs once per set rather than per user
    representatives = role_sets.invert
    users           = User.where(id: representatives.values).index_by(&:id)
    levels          = representatives.transform_values { |user_id| level_for(users[user_id]) }

    role_sets.transform_values { |role_set| levels[role_set] }
  end

  # Hash of user id to their sorted active role ids, [] for a user without any.
  def self.role_sets_for(user_ids)
    by_user = User
      .joins(:roles)
      .where(users: { id: user_ids }, roles: { active: true })
      .pluck(Arel.sql('users.id'), Arel.sql('roles.id'))
      .group_by(&:first)
      .transform_values { |rows| rows.map(&:last).sort }

    user_ids.index_with { |user_id| by_user.fetch(user_id, []) }
  end
  private_class_method :role_sets_for

  # An explicit level renders assets for an audience rather than for a concrete user, which is
  #   what a broadcast without a recipient needs. @see UserInfo.with_assets_level
  def initialize(current_user_id, level: nil)
    @current_user_id = current_user_id
    @user = User.find_by(id: current_user_id) if current_user_id.present?

    self.level = level || self.class.level_for(user)
  end

  def admin?
    check_level?(UserInfo::Assets::LEVEL_ADMIN)
  end

  def agent?
    check_level?(UserInfo::Assets::LEVEL_AGENT)
  end

  def customer?
    check_level?(UserInfo::Assets::LEVEL_CUSTOMER)
  end

  # A blank level is not privileged: a context that was cleared or never established must not
  #   unlock agent or admin level data. Userless work that legitimately needs full access has
  #   to say so via UserInfo.with_system_context.
  #
  # A level without a user names an audience rather than a recipient, and outranks the system
  #   context: work that knows who it is rendering for must render for them even when it runs
  #   as the system. @see UserInfo.with_assets_level
  def check_level?(check)
    return UserInfo.system_context? if level.blank?

    level >= check
  end
end
