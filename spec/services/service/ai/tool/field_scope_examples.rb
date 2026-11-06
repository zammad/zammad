# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Finds the fields of a tool result that the reader's field scope denies. Every object row of the result — a hash with
#   `type` and `id`, as Service::AI::Tool::Output builds them — is checked against its record's policy, as GraphQL's
#   scoped fields are checked.
module AIToolFieldScopeHelper
  def field_scoped_rows_in(content, reader:)
    rows_in(content).select { |row| field_scope_of(row, reader).respond_to?(:field_authorized?) }
  end

  # @return [Array<String>] "<type> <id>: <field>" for every denied field found, empty when none is
  def denied_fields_in(content, reader:)
    field_scoped_rows_in(content, reader:).flat_map do |row|
      record = record_of(row)
      scope  = field_scope_of(row, reader)

      row.keys.select { |field| denied?(scope, field, record) }.map { |field| "#{row[:type]} #{row[:id]}: #{field}" }
    end
  end

  private

  def rows_in(content)
    case content
    when Hash
      row = content[:type].is_a?(String) && content.key?(:id) && record_of(content) ? [content] : []
      row + content.values.flat_map { |value| rows_in(value) }
    when Array
      content.flat_map { |value| rows_in(value) }
    else
      []
    end
  end

  def record_of(row)
    model = row[:type].safe_constantize
    return if !model.is_a?(Class) || !(model < ApplicationModel)

    model.find_by(id: row[:id])
  end

  def field_scope_of(row, reader)
    Pundit.policy(reader, record_of(row)).show?
  end

  # An allow list names every field it allows, so a row's own facts that are no fields of the record pass it.
  def denied?(scope, field, record)
    return false if scope.field_authorized?(field)

    scope.deny&.include?(field.to_sym) || record.has_attribute?(field)
  end
end

# The permission case of a tool that returns objects a reader may see with a field scope only.
#
# Needs: `reader` (whose policy gives a field scope on at least one returned object) and `tool_result` (the result of
#   the tool run as the reader).
RSpec.shared_examples 'an AI tool returning only the fields the reader may see' do
  include AIToolFieldScopeHelper

  it 'returns no field the reader\'s field scope denies', :aggregate_failures do
    expect(field_scoped_rows_in(tool_result.content, reader:)).to be_present
    expect(denied_fields_in(tool_result.content, reader:)).to be_empty
  end
end
