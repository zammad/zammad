# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A persisted record writes secondary organization join rows at once, before a save could validate
#   them, and a caller may assign the user's primary organization only afterwards. The check therefore
#   runs on the persisted state when the surrounding transaction commits and rolls it back on failure.
#   Rails offers a before_commit block only on the internal transaction object.
module ChecksSecondaryOrganizationsOnCommit
  extend ActiveSupport::Concern

  private

  def check_secondary_organizations_on_commit(users)
    transaction = self.class.connection.current_transaction
    return if @secondary_organizations_check_transaction.equal?(transaction)

    @secondary_organizations_check_transaction = transaction

    transaction.before_commit do
      @secondary_organizations_check_transaction = nil
      next if !users.joins(:organizations).where('organizations.id = users.organization_id').exists?

      errors.add :base, __('Secondary organizations cannot include the primary organization.')
      raise ActiveRecord::RecordInvalid, self
    end
  end
end
