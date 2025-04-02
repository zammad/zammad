# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AddArticleLanguageDetection, db_strategy: :reset, type: :db_migration do
  before do
    Setting.find_by(name: 'language_detection_article').destroy!
    ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('TicketArticle'), name: 'detected_language').destroy!
    remove_column :ticket_articles, :detected_language
    Ticket::Article.reset_column_information
  end

  it 'adds new table column, object attribute and setting' do
    expect { migrate }.to change { Ticket::Article.column_for_attribute(:detected_language) }
      .and change { ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('TicketArticle'), name: 'detected_language')&.data_option&.dig('historical_options', 'de') }
      .and change { Setting.find_by(name: 'language_detection_article') }
  end
end
