# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Validations::TicketArticleValidator::Default do
  it 'is called when a ticket article is created' do
    expect_any_instance_of(described_class).to receive(:validate)

    create(:ticket_article)
  end

  describe '#validate' do
    it 'passes with body present' do
      instance = build(:ticket_article, body: 'sample body')

      described_class.new(instance).validate

      expect(instance.errors).to be_blank
    end

    it 'fails if body is blank' do
      instance = build(:ticket_article, body: '')

      described_class.new(instance).validate

      expect(instance.errors).to have_attributes(
        errors: include(have_attributes(message: match(%r{Need at least an 'article body' field.})))
      )
    end
  end
end
