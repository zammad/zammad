# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Case-insensitive indexes', type: :model do
  # LOWER() indexes back the case-insensitive uniqueness validations of their
  # models. Any other index on a name-like column is expected to be plain.
  let(:expected) do
    Models.all.keys
      .flat_map { |model| case_insensitive_uniqueness_index_names(model) }
      .uniq - validated_over_plain_index
  end

  # Not a name-like column, so it never had an implicit LOWER() index.
  let(:validated_over_plain_index) { %w[index_ai_feature_providers_on_identifier] }

  let(:actual) do
    ActiveRecord::Base.connection.select_values(<<~SQL.squish)
      SELECT indexname
      FROM pg_indexes
      WHERE schemaname = current_schema()
        AND indexdef ILIKE '%lower(%'
    SQL
  end

  def case_insensitive_uniqueness_index_names(model)
    model.validators
      .select { |validator| validator.is_a?(ActiveRecord::Validations::UniquenessValidator) && validator.options[:case_sensitive] == false }
      .flat_map { |validator| validator.attributes.map { |attribute| "index_#{model.table_name}_on_#{attribute}" } }
  end

  it 'exist exactly where a model validates uniqueness case-insensitively' do
    expect(actual).to match_array(expected)
  end
end
