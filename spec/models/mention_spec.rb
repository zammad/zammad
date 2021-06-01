# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:ticket) { create(:ticket) }

  describe 'validation' do
    it 'does not allow mentions for customers' do
      expect { create(:mention, mentionable: ticket, user: create(:customer)) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: User has no ticket.agent permissions')
    end
  end
end
