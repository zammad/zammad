# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The order a list comes in where the caller chooses it, named as the REST API names it: sort_by, one of a short list of
#   fields, and order_by, its direction, which alone turns the list's own field around. The ID sorts after the field, so
#   that pages taken by offset neither repeat nor skip a record. The cursor of a page belongs to its order, as to every
#   other argument.
module Service::AI::Tool::Concerns::Sorting
  extend ActiveSupport::Concern

  DIRECTIONS = %w[asc desc].freeze

  class_methods do
    # @param fields [Array<String>] what the list can be sorted by
    # @param default [String] the order without sort_by, for its description
    def sortable(fields, default:)
      # Written for the model, like every text a tool returns, so not translated.
      # rubocop:disable Zammad/DetectTranslatableString
      parameter :sort_by, type: :string, enum: fields, description: "The field to sort by. Otherwise #{default}."
      parameter :order_by, type: :string, enum: DIRECTIONS,
                           description: 'The direction: asc for the oldest, earliest or A first, desc for the newest, latest or Z first. Otherwise desc.'
      # rubocop:enable Zammad/DetectTranslatableString
    end
  end

  private

  def sorted?
    argument(:sort_by).present? || argument(:order_by).present?
  end

  def sort_direction
    argument(:order_by) || 'desc'
  end

  # @param field [String] what the list sorts by where the caller names no field
  # @return [Array(Array<String>, Array<String>)] the fields and directions for a model's search
  def search_sorting(field)
    [[argument(:sort_by) || field, 'id'], [sort_direction] * 2]
  end
end
