# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TemplatePolicy::Scope do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { Template }

  let(:active_template) { create(:template, :dummy_data, active: true) }
  let(:inactive_template) { create(:template, :dummy_data, active: false) }

  before do
    Template.destroy_all
    active_template && inactive_template
  end

  describe '#resolve' do
    context 'without user' do
      let(:user) { nil }

      it 'throws exception' do
        expect { scope.resolve }.to raise_error %r{Authentication required}
      end
    end

    context 'with customer' do
      let(:user) { create(:customer) }

      it 'returns empty' do
        expect(scope.resolve).to be_empty
      end
    end

    context 'with agent' do
      let(:user) { create(:agent) }

      it 'returns active template only' do
        expect(scope.resolve).to match_array [active_template]
      end
    end

    context 'with admin' do
      let(:user) { create(:admin) }

      it 'returns all templates' do
        expect(scope.resolve).to match_array [active_template, inactive_template]
      end
    end
  end
end
