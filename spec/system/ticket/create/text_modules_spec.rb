# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/text_modules_examples'

RSpec.describe 'Ticket Create > Text modules', time_zone: 'Europe/London', type: :system do
  context 'when using text modules' do
    include_examples 'text modules', path: 'ticket/create'
  end
end
