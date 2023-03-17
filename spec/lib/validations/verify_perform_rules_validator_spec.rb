# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

class SampleModel
  include ActiveModel::Validations

  attr_accessor :sample

  validates :sample, 'validations/verify_perform_rules': true
end

RSpec.describe Validations::VerifyPerformRulesValidator do
  let(:instance) { SampleModel.new }

  context 'when validating presence' do
    it 'is valid when attribute is empty' do
      instance.sample = {}
      expect(instance).to be_valid
    end

    it 'is valid when attribute is nil' do
      instance.sample = nil
      expect(instance).to be_valid
    end

    it 'is valid when attribute does not have checkable keys' do
      instance.sample = { test: :value }
      expect(instance).to be_valid
    end

    it 'is valid when required value is present' do
      instance.sample = { 'article.note' => { 'body' => 'a', 'subject' => 'b', 'internal' => 'c' } }
      expect(instance).to be_valid
    end

    it 'is invalid when required value is missing' do
      instance.sample = { 'article.note' => {} }
      instance.valid?

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{The required 'sample' value for article.note, internal is missing!})))
      )
    end

    it 'is invalid when required value is partially missing' do
      instance.sample = { 'article.note' => { 'body' => 'a', 'subject' => 'b' } }
      instance.valid?

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{The required 'sample' value for article.note, internal is missing!})))
      )
    end
  end

  context 'when validating presence with precondition' do
    it 'is valid when required value for specific precondition is present' do
      instance.sample = { 'ticket.customer_id' => { 'pre_condition' => 'specific', 'value' => '123' } }
      expect(instance).to be_valid
    end

    it 'is valid when required value without specific precondition is not present' do
      instance.sample = { 'ticket.customer_id' => { 'pre_condition' => 'current' } }
      expect(instance).to be_valid
    end

    it 'is invalid when required value for specific precondition is not present' do
      instance.sample = { 'ticket.customer_id' => { 'pre_condition' => 'specific', 'value' => '' } }
      instance.valid?

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{The required 'sample' value for ticket.customer_id, value is missing!})))
      )
    end
  end
end
