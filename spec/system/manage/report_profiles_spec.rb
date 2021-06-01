# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Report Profiles', type: :system do
  context 'ajax pagination' do
    include_examples 'pagination', model: :report_profile, klass: Report::Profile, path: 'manage/report_profiles'
  end
end
