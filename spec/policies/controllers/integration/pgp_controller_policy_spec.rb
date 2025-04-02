# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::Integration::PGPControllerPolicy do
  subject { described_class.new(user, record) }

  let(:record_class) { Integration::PGPController }

  let(:record) { record_class.new }

  context 'when admin' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(%i[key_list key_show key_download key_add key_delete status search]) }
  end

  context 'when agent' do
    let(:user) { create(:agent) }

    it { is_expected.to permit_actions(%i[search]) }
    it { is_expected.to forbid_actions(%i[key_list key_show key_download key_add key_delete status]) }
  end

  context 'when customer' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(%i[key_list key_show key_download key_add key_delete status search]) }
  end
end
