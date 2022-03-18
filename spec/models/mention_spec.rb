# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:ticket) { create(:ticket) }

  describe 'validation' do
    it 'does not allow mentions for customers' do
      expect { create(:mention, mentionable: ticket, user: create(:customer)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: User has no ticket.agent permissions')
    end
  end
end
