require 'rails_helper'
require 'lib/import/zendesk/ticket/comment/local_id_lookup_backend_examples'

RSpec.describe Import::Zendesk::Ticket::Comment::Sender do
  it_behaves_like 'local_id lookup backend'
end
