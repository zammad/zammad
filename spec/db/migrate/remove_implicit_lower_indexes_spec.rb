# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RemoveImplicitLowerIndexes, db_strategy: :reset, type: :db_migration do
  let(:connection) { ActiveRecord::Base.connection }

  def index_name(table, columns)
    "index_#{table}_on_#{columns.join('_and_')}"
  end

  def index_for(table, columns)
    connection.indexes(table).find { |index| index.name == index_name(table, columns) }
  end

  def indexes_over(table, columns)
    connection.indexes(table).select do |index|
      Array(index.columns).join(', ').gsub(%r{lower\(\((\w+)\)::text\)}, '\1') == columns.join(', ')
    end
  end

  def lower_expression(columns)
    columns
      .map { |column| column == :object_lookup_id ? column.to_s : "LOWER(#{column})" }
      .join(', ')
  end

  def expect_plain_indexes(name: method(:index_name))
    described_class::INDEXES.each do |table, columns, unique|
      expect(indexes_over(table, columns))
        .to contain_exactly(have_attributes(name: name.call(table, columns), columns: columns.map(&:to_s), unique: unique)), "#{table}: expected one plain index"
    end
  end

  def expect_case_insensitive_indexes
    described_class::CASE_INSENSITIVE_INDEXES.each do |table, column|
      expect(indexes_over(table, [column]))
        .to contain_exactly(have_attributes(name: index_name(table, [column]), columns: "lower((#{column})::text)", unique: true)), "#{table}: expected one LOWER() index"
    end
  end

  context 'when the indexes are still case-insensitive' do
    before do
      described_class::INDEXES.each do |table, columns, unique|
        connection.remove_index table, name: index_name(table, columns)
        connection.add_index table, lower_expression(columns), unique: unique, name: index_name(table, columns)
      end
    end

    it 'replaces them with plain indexes' do
      migrate

      expect_plain_indexes
    end

    it 'keeps the indexes backing case-insensitive validations' do
      migrate

      expect_case_insensitive_indexes
    end
  end

  context 'when the tokens index predates the rename of its column' do
    before do
      connection.remove_index :tokens, name: index_name(:tokens, %i[token action])
      connection.add_index :tokens, 'LOWER(token), action', unique: true, name: index_name(:tokens, %i[name action])
    end

    it 'replaces it with the plain index of new installations' do
      expect { migrate }
        .to change { index_for(:tokens, %i[name action]) }.to(nil)
        .and change { index_for(:tokens, %i[token action])&.then { [it.columns, it.unique] } }.to([%w[token action], true])
    end
  end

  context 'when the indexes are already plain' do
    it 'keeps them plain' do
      migrate

      expect_plain_indexes
    end
  end

  context 'when the system was moved from MySQL with pgloader' do
    def pgloader_index_name(table, columns)
      oid = connection.select_value("SELECT #{connection.quote(table.to_s)}::regclass::oid")

      "idx_#{oid}_#{index_name(table, columns)}".first(63)
    end

    def replace_with_pgloader_index(table, columns, unique)
      connection.remove_index table, name: index_name(table, columns)
      connection.add_index table, columns, unique: unique, name: pgloader_index_name(table, columns)
    end

    before do
      described_class::INDEXES.each do |table, columns, unique|
        replace_with_pgloader_index(table, columns, unique)
      end

      described_class::CASE_INSENSITIVE_INDEXES.each do |table, column|
        replace_with_pgloader_index(table, [column], true)
      end

      replace_with_pgloader_index(:tokens, %i[token action], true)
    end

    it 'keeps the plain indexes without adding a second one' do
      migrate

      expect_plain_indexes(name: method(:pgloader_index_name))
    end

    it 'keeps the tokens index without adding a second one' do
      migrate

      expect(indexes_over(:tokens, %i[token action]))
        .to contain_exactly(have_attributes(name: pgloader_index_name(:tokens, %i[token action])))
    end

    it 'turns the indexes backing case-insensitive validations into LOWER() indexes' do
      migrate

      expect_case_insensitive_indexes
    end

    context 'when names differ only in case' do
      before do
        create(:signature, name: 'Sales')
        build(:signature, name: 'SALES').save!(validate: false)
        allow(Rails.logger).to receive(:warn)
      end

      it 'keeps the case-sensitive index' do
        migrate

        expect(indexes_over(:signatures, [:name]))
          .to contain_exactly(have_attributes(name: pgloader_index_name(:signatures, [:name]), columns: ['name'], unique: true))
      end

      it 'logs the duplicate names' do
        migrate

        expect(Rails.logger).to have_received(:warn).with(include('signatures (name)').and(include('sales')))
      end
    end
  end
end
