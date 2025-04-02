# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Ticket::TimeAccounting::Type, type: :model do
  subject(:time_accounting_type) { create(:ticket_time_accounting_type) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
end
