# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationPolicy::FieldScope do
  subject(:field_scope) { described_class.new(allow: allow_fields, deny: deny_fields) }

  let(:allow_fields) { nil }
  let(:deny_fields)  { nil }

  context 'when only allowing fields' do
    let(:allow_fields) { [:field1] }

    it 'accepts allowlisted fields' do
      expect(field_scope.field_authorized?(:field1)).to be(true)
    end

    it 'denies unknown fields' do
      expect(field_scope.field_authorized?(:field2)).to be(false)
    end
  end

  context 'when only denying fields' do
    let(:deny_fields) { [:field1] }

    it 'rejects denylisted fields' do
      expect(field_scope.field_authorized?(:field1)).to be(false)
    end

    it 'allows unknown fields' do
      expect(field_scope.field_authorized?(:field2)).to be(true)
    end
  end

  context 'when both allowing and denying' do
    let(:allow_fields) { [:field1] }
    let(:deny_fields) { [:field2] }

    it 'accepts allowlisted fields' do
      expect(field_scope.field_authorized?(:field1)).to be(true)
    end

    it 'rejects denylisted fields' do
      expect(field_scope.field_authorized?(:field2)).to be(false)
    end

    it 'rejects unknown fields' do
      expect(field_scope.field_authorized?(:field3)).to be(false)
    end
  end
end
