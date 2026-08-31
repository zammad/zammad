# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::Enum::KnowledgeBase::SchedulableVisibilityType do
  let(:values) { described_class.values.values.map(&:value) }

  # A state can only be scheduled if it is stored as a date, which is what the model's map says -
  #   so a state added there has to be offered here, and one this enum offers without a column
  #   would only surface when somebody picks it.
  it 'offers every state that is stored as a date' do
    expect(values).to match_array(CanBePublished::SCHEDULABLE_VISIBILITIES.keys)
  end

  # The full state list of the answer, minus the one that stores no date - said the other way
  #   round, so a new state in either enum shows up here.
  it 'offers the answer states except the one that stores no date' do
    expect(values)
      .to match_array(Gql::Types::Enum::KnowledgeBase::VisibilityType.values.values.map(&:value) - [:draft])
  end
end
