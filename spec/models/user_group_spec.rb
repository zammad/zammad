# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_group_relation_definition_examples'

RSpec.describe UserGroup do

  let!(:group_relation_instance) { create(:agent) }

  it_behaves_like 'HasGroupRelationDefinition'
end
