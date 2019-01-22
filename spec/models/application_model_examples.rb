require 'models/application_model/checks_import_examples'

RSpec.shared_examples 'ApplicationModel' do
  include_examples 'ApplicationModel::ChecksImport',
                   importable: described_class.name.in?(
                     %w[Group
                        History
                        Role
                        Ticket
                        Ticket::Article
                        Ticket::Priority
                        Ticket::State
                        Ticket::StateType
                        User]
                   )
end
