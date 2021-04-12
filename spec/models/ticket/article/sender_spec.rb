# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Ticket::Article::Sender, type: :model do
  it_behaves_like 'HasCollectionUpdate', collection_factory: :ticket_article_sender
  it_behaves_like 'HasXssSanitizedNote', model_factory: :ticket_article_sender
end
