# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::KnowledgeBase::FeedsControllerPolicy do
  subject { described_class.new(user, record) }

  include_context 'basic Knowledge Base'

  let(:record_class) { KnowledgeBase::FeedsController }
  let(:params)       { {} }

  let(:record) do
    rec        = record_class.new
    rec.params = params

    rec
  end

  context 'with KB user' do
    let(:user) { create(:admin) }

    it { is_expected.to permit_actions(:root, :category) }
  end

  context 'with non-KB user' do
    let(:user) { create(:customer) }

    it { is_expected.to forbid_actions(:root, :category) }
  end

  context 'with token with KB user' do
    let(:user)   { create(:admin) }
    let(:token)  { create(:token, action: 'KnowledgeBaseFeed', user: user) }
    let(:params) { { token: token.name } }

    it { is_expected.to permit_actions(:root, :category) }
  end

  context 'with token with non-KB user' do
    let(:user)   { create(:customer) }
    let(:token)  { create(:token, action: 'KnowledgeBaseFeed', user: user) }
    let(:params) { { token: token.name } }

    it { is_expected.to forbid_actions(:root, :category) }
  end

  context 'with nonexistant token' do
    let(:user)   { nil }
    let(:params) { { token: 'foobar' } }

    it { is_expected.to forbid_actions(:root, :category) }
  end

  context 'without both token and user' do
    let(:user) { nil }

    it { is_expected.to forbid_actions(:root, :category) }
  end
end
