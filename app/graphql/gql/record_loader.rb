# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# https://github.com/Shopify/graphql-batch/blob/af45e5b9e560abb8eb2b97657928e460d4dcf96a/examples/record_loader.rb
class Gql::RecordLoader < GraphQL::Batch::Loader # rubocop:disable GraphQL/ObjectDescription
  def initialize(model, column: model.primary_key, where: nil)
    super()
    @model = model
    @column = column.to_s
    @column_type = model.type_for_attribute(@column)
    @where = where
  end

  def load(key)
    super(@column_type.cast(key))
  end

  def perform(keys)
    query(keys).each { |record| fulfill(record.public_send(@column), record) }
    keys.each { |key| fulfill(key, nil) if !fulfilled?(key) }
  end

  private

  def query(keys)
    scope = @model
    scope = scope.where(@where) if @where
    scope.where(@column => keys)
  end
end
