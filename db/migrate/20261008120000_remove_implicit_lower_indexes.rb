# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RemoveImplicitLowerIndexes < ActiveRecord::Migration[8.1]
  # A former core extension silently turned every index on these columns into
  # a LOWER() expression index. Nothing queries them case-insensitively, so a
  # plain index is what the lookups can actually use.
  INDEXES = [
    [:ai_analytics_runs, [:ai_service_name], false],
    [:authorizations, [:username], false],
    [:history_attributes, [:name], true],
    [:history_objects, [:name], true],
    [:history_types, [:name], true],
    [:link_objects, [:name], true],
    [:link_types, [:name], true],
    [:locales, [:locale], true],
    [:locales, [:name], true],
    [:object_lookups, [:name], true],
    [:object_manager_attributes, %i[object_lookup_id name], true],
    [:overviews, [:name], false],
    [:permissions, [:name], true],
    [:settings, [:name], true],
    [:store_objects, [:name], true],
    [:tag_objects, [:name], true],
    [:templates, [:name], false],
    [:text_modules, [:name], false],
    [:ticket_article_senders, [:name], true],
    [:ticket_article_types, [:name], true],
    [:translations, [:locale], false],
    [:type_lookups, [:name], true],
  ].freeze

  # These back case-insensitive uniqueness validations. The extension only
  # patched PostgreSQL, so systems moved from MySQL got them as plain indexes.
  CASE_INSENSITIVE_INDEXES = [
    %i[ai_agents name],
    %i[ai_provider_connections name],
    %i[ai_text_tools name],
    %i[calendars name],
    %i[chats name],
    %i[core_workflows name],
    %i[groups name],
    %i[jobs name],
    %i[ldap_sources name],
    %i[macros name],
    %i[organizations name],
    %i[report_profiles name],
    %i[roles name],
    %i[schedulers name],
    %i[signatures name],
    %i[slas name],
    %i[ticket_priorities name],
    %i[ticket_state_types name],
    %i[ticket_states name],
    %i[ticket_time_accounting_types name],
    %i[triggers name],
    %i[users login],
  ].freeze

  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    INDEXES.each do |table, columns, unique|
      ensure_index table, columns.map(&:to_s), unique: unique
    end

    CASE_INSENSITIVE_INDEXES.each do |table, column|
      ensure_index table, ["LOWER(#{column})"], unique: true
    end

    # Systems set up before Zammad 6.0 kept the implicit index on tokens.name
    # under its old name when that column was renamed to token.
    ensure_index :tokens, %w[token action], unique: true
  end

  private

  # pgloader prefixed the names of all indexes it took over from MySQL with
  # idx_<table oid>_, so the existing index is found by its columns.
  def ensure_index(table, key, unique:)
    columns = key_columns(key)
    indexes = connection.indexes(table).select { |index| key_columns(index_key(index)) == columns }
    return if indexes.one? && index_key(indexes.first) == key && indexes.first.unique == unique

    duplicates = unique ? duplicate_values(table, key) : []
    if duplicates.any?
      Rails.logger.warn "The index on #{table} (#{columns.join(', ')}) was left unchanged, as a unique index on #{key.join(', ')} would reject these values: #{duplicates.join('; ')}"
      return
    end

    indexes.each { |index| remove_index table, name: index.name }
    add_index table, key.join(', '), unique: unique, name: "index_#{table}_on_#{columns.join('_and_')}"
  end

  def index_key(index)
    return index.columns if index.columns.is_a?(Array)

    index.columns.split(', ').map { |part| part.sub(%r{\Alower\(\(?(\w+)\)?(?:::text)?\)\z}, 'LOWER(\1)') }
  end

  def key_columns(key)
    key.map { |part| part[%r{\ALOWER\((\w+)\)\z}, 1] || part }
  end

  # Systems moved from MySQL lost the case-insensitive uniqueness of its
  # collation, and not every model enforced it on its own.
  def duplicate_values(table, key)
    connection.select_rows(<<~SQL.squish).map { |row| row.join(', ') }
      SELECT #{key.join(', ')} FROM #{table}
      WHERE #{key_columns(key).map { |column| "#{column} IS NOT NULL" }.join(' AND ')}
      GROUP BY #{key.join(', ')}
      HAVING COUNT(*) > 1
    SQL
  end
end
