# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveRecord::Locking::Pessimistic do
  let!(:ticket) { create(:ticket) }

  def set_old_ticket_store

    # set old store
    ActiveRecord::Base.connection.execute("UPDATE tickets SET preferences = '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
 form: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
   remote_ip: 111.111.98.123
   fingerprint_md5: 66638aad396c60ecb24f96de1e59d111' WHERE id = #{ticket.id}")

    # kill cache
    Rails.cache.clear

    # reload ticket and make sure that the store is deserialized
    ticket.reload.preferences
  end

  it 'does raise the error for changes before lock' do
    ticket.updated_at = Time.zone.now
    expect { ticket.lock! }.to raise_error(RuntimeError)
  end

  it 'does not raise the error if the store has changes but only structure changed' do
    set_old_ticket_store
    expect do
      ticket.lock!
      ticket.update(title: SecureRandom.uuid)
    end.not_to raise_error
  end
end
