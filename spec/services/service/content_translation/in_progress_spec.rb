# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::ContentTranslation::InProgress do
  subject(:in_progress) { described_class.execute(objects: articles, target_locale:) }

  let(:articles)      { create_list(:ticket_article, 3) }
  let(:target_locale) { 'de-de' }

  # A lock created and updated at the same time is still queued; its job touches it on start.
  def lock(article, locale = target_locale, updated_at: Time.zone.now, created_at: updated_at)
    ActiveJobLock.create!(
      lock_key:      ContentTranslationJob.lock_key_for(article, locale),
      active_job_id: SecureRandom.uuid,
      created_at:,
      updated_at:,
    )
  end

  def lock_queries(&)
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      queries << payload[:sql] if payload[:sql].include?('"active_job_locks"')
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it 'returns nothing without locks' do
    expect(in_progress).to be_empty
  end

  it 'returns the articles whose translation into the locale is locked, in the order given' do
    lock(articles.last)
    lock(articles.first)

    expect(in_progress).to eq([articles.first, articles.last])
  end

  it 'ignores locks for another locale' do
    lock(articles.first, 'fr-fr')

    expect(in_progress).to be_empty
  end

  it 'counts a lock from the moment its job started' do
    lock(articles.first, updated_at: 1.minute.ago, created_at: 1.hour.ago)

    expect(in_progress).to eq([articles.first])
  end

  it 'ignores a job that started longer ago than a translation can run' do
    lock(articles.first, updated_at: (described_class::MAX_AGE + 1.minute).ago, created_at: 2.hours.ago)

    expect(in_progress).to be_empty
  end

  it 'counts a job still waiting in the queue for longer' do
    lock(articles.first, updated_at: (described_class::MAX_AGE + 1.minute).ago)

    expect(in_progress).to eq([articles.first])
  end

  it 'ignores a job waiting longer than a queue does' do
    lock(articles.first, updated_at: (described_class::MAX_QUEUED_AGE + 1.minute).ago)

    expect(in_progress).to be_empty
  end

  it 'reads the locks of all articles in one query' do
    articles.each { |article| lock(article) }

    expect(lock_queries { in_progress }.size).to eq(1)
  end

  it 'matches the key of an enqueued job' do
    ContentTranslationJob.perform_later(articles.second, target_locale, service: 'Service::ContentTranslation::TicketArticle')

    expect(in_progress).to eq([articles.second])
  end

  it 'returns nothing for no articles without asking' do
    expect(lock_queries { described_class.execute(objects: [], target_locale:) }).to be_empty
  end
end
