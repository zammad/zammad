# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe UploadCachePolicy do
  subject { described_class.new(user, record) }

  let(:record) { UploadCache.new(123) }
  let(:user)   { create(:user) }

  context 'without a user' do
    let(:user) { nil }

    it { is_expected.to permit_actions :show, :destroy }
  end

  context 'with a user' do
    it { is_expected.to permit_actions :show, :destroy }
  end
end
