require 'rails_helper'
require 'lib/import/zendesk/ticket/sub_object_factory_examples'

RSpec.describe Import::Zendesk::Ticket::CommentFactory do
  it_behaves_like 'Import::Zendesk::Ticket::SubObjectFactory'
end
