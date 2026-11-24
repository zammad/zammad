# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ActiveRecord::Calculations, '#count_rows' do
  let(:tickets)  { create_list(:ticket, 3) }
  let(:relation) { Ticket.where(id: tickets.map(&:id)) }

  before do
    tickets.each { |ticket| create_list(:ticket_article, 2, ticket:) }
  end

  it 'counts the rows of a relation' do
    expect(relation.count_rows).to eq(3)
  end

  it 'counts the groups of a grouped relation' do
    expect(relation.joins(:articles).group('tickets.id').count_rows).to eq(3)
  end

  it 'counts the groups of a grouped relation that was loaded before' do
    grouped = relation.joins(:articles).group('tickets.id')
    grouped.load

    expect(grouped.count_rows).to eq(3)
  end

  it 'counts the groups of a grouped relation whose SQL was built before' do
    grouped = relation.joins(:articles).group('tickets.id')
    grouped.to_sql

    expect(grouped.count_rows).to eq(3)
  end

  it 'counts the groups of a grouped distinct relation' do
    expect(relation.joins(:articles).group('tickets.id').distinct.count_rows).to eq(3)
  end

  it 'counts the groups of a grouped relation up to its limit' do
    expect(relation.joins(:articles).group('tickets.id').limit(2).count_rows).to eq(2)
  end

  it 'counts the groups of a grouped relation ordered by a selected column' do
    ordered = relation
      .joins(:articles)
      .group('tickets.id')
      .select('tickets.*, tickets.title AS sorted_title')
      .reorder('sorted_title')

    expect(ordered.count_rows).to eq(3)
  end

  it 'counts a relation grouped by qualified columns without its select list' do
    grouped = relation
      .joins('INNER JOIN "users" "owners" ON "owners"."id" = "tickets"."owner_id"')
      .group('tickets.id', '"owners"."firstname", "owners"."lastname"')
      .select('tickets.*, "owners"."lastname" AS owner_name')

    queries  = []
    callback = ->(*, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { grouped.count_rows }

    expect(queries).to include(start_with('SELECT COUNT(*) FROM (SELECT 1 FROM'))
  end

  context 'with tickets in two states' do
    before do
      tickets.first.update!(state: Ticket::State.lookup(name: 'open'))
    end

    it 'counts the groups of a relation grouped by an alias of its select list' do
      expect(relation.select('tickets.state_id AS state_key').group('state_key').count_rows).to eq(2)
    end

    it 'counts the distinct rows of a grouped distinct relation' do
      expect(relation.select(:state_id).group(:id, :state_id).distinct.count_rows).to eq(2)
    end
  end
end
