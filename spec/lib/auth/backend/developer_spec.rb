# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/auth/backend/backend_examples'

RSpec.describe Auth::Backend::Developer do

  let(:user)     { create(:user) }
  let(:password) { 'not_used' }
  let(:auth)     { Auth.new(user.login, password) }
  let(:instance) { described_class.new({ adapter: described_class.name }, auth) }

  describe '#valid?' do
    it_behaves_like 'Auth backend'

    context 'when Setting developer_mode is true' do

      before do
        Setting.set('developer_mode', true)
      end

      context 'when password is "test"' do

        let(:password) { 'test' }

        it 'authenticates' do
          expect(instance.valid?).to be true
        end
      end

      context 'when password matches actual User password' do

        let(:user)     { create(:user, password: 'secure') }
        let(:password) { user.password_plain }

        it "doesn't authenticate" do
          expect(instance.valid?).to be false
        end
      end
    end

    context 'when Rails.env is "test"' do

      before do
        allow(Rails).to receive(:env) { 'test'.inquiry } # rubocop:disable Rails/Inquiry
      end

      context 'when password is blank' do

        let(:password) { '' }

        it 'authenticates' do
          expect(instance.valid?).to be true
        end
      end

      context 'when password matches actual User password' do

        let(:user)     { create(:user, password: 'secure') }
        let(:password) { user.password_plain }

        it "doesn't authenticate" do
          expect(instance.valid?).to be false
        end
      end
    end

    context 'when Rails.env is "production"' do

      before do
        allow(Rails).to receive(:env) { 'production'.inquiry } # rubocop:disable Rails/Inquiry
      end

      context 'when password is blank' do

        let(:password) { '' }

        it "doesn't authenticate" do
          expect(instance.valid?).to be false
        end
      end

      context 'when password matches actual User password' do

        let(:user)     { create(:user, password: 'secure') }
        let(:password) { user.password_plain }

        it "doesn't authenticate" do
          expect(instance.valid?).to be false
        end
      end
    end
  end
end
