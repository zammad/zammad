# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  context 'when validating pending state actions' do
    %i[pending_reminder pending_action].each do |category|
      context "with #{category} state via ticket.state_id" do
        let(:pending_state) { Ticket::State.by_category(category).first }

        it 'is invalid without pending_time' do
          instance.sample = {
            'ticket.state_id' => { 'value' => pending_state.id.to_s }
          }
          instance.valid?

          expect(instance.errors[:base]).to be_present
        end

        it 'is valid with pending_time' do
          instance.sample = {
            'ticket.state_id'     => { 'value' => pending_state.id.to_s },
            'ticket.pending_time' => { 'value' => 1.day.from_now }
          }

          expect(instance).to be_valid
        end
      end
    end

    it 'is invalid when a pending state is set via ticket.state name without pending_time' do
      instance.sample = {
        'ticket.state' => { 'value' => Ticket::State.by_category(:pending).first.name }
      }
      instance.valid?

      expect(instance.errors[:base]).to be_present
    end

    it 'is valid when state is not a pending state' do
      instance.sample = {
        'ticket.state_id' => { 'value' => Ticket::State.lookup(name: 'open').id.to_s }
      }

      expect(instance).to be_valid
    end
  end
end
