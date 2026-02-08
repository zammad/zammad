# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5254UserOrganizationUniqueness < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    return if !non_unique_organizations_in_users?

    remove_non_unique_organizations_from_users
    update_affected_users
  end

  private

  def user_ids
    @user_ids ||= User.joins(:organizations_users)
                      .where('organizations_users.organization_id = users.organization_id')
                      .pluck(:id)
  end

  def non_unique_organizations_in_users?
    !user_ids.empty?
  end

  def remove_non_unique_organizations_from_users
    # Drop offending records via raw SQL statement, since it's atomic and much more performant than going through Rails.
    #   It has a side-effect of not triggering any callbacks or validations, which is desirable in this case.
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      DELETE FROM organizations_users
      USING users
      WHERE organizations_users.user_id = users.id
        AND organizations_users.organization_id = users.organization_id
    SQL
  end

  def update_affected_users
    ActiveRecord::Base.connection.exec_update(<<~SQL.squish)
      UPDATE users
      SET updated_at=NOW(), updated_by_id=1
      WHERE id IN (#{user_ids.join(',')})
    SQL
  end
end
