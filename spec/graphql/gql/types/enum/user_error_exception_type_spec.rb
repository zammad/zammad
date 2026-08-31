# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::Enum::UserErrorExceptionType, type: :graphql do
  let(:values) { described_class.values.keys }

  # The regression that matters: the enum used to be built from the ticket update validator alone,
  #   and the frontend matches on these exact strings (`error.getFirstErrorException()`). Collecting
  #   from more services must not drop or rename any of them.
  it 'still exposes every ticket update validator exception', :aggregate_failures do
    expect(Service::Ticket::Update::Validator.exceptions).not_to be_empty

    Service::Ticket::Update::Validator.exceptions.each do |exception|
      expect(values).to include(IdentifierName.encode(exception.name))
    end
  end

  it 'exposes the knowledge base answer update validator exceptions', :aggregate_failures do
    expect(Service::KnowledgeBase::Answer::Update::Validator.exceptions).not_to be_empty

    Service::KnowledgeBase::Answer::Update::Validator.exceptions.each do |exception|
      expect(values).to include(IdentifierName.encode(exception.name))
    end
  end

  # Every listed service has to be loaded when the enum is built, or `descendants` silently comes up
  #   short and the enum loses values without anything failing.
  it 'has a value for every listed validator exception' do
    listed = described_class::VALIDATORS.flat_map(&:exceptions)

    expect(values.size).to eq(listed.size)
  end
end
