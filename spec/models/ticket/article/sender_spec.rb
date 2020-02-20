require 'rails_helper'
require 'models/concerns/has_collection_update_examples'

RSpec.describe Ticket::Article::Sender, type: :model do
  it_behaves_like 'HasCollectionUpdate', collection_factory: :ticket_article_sender
end
