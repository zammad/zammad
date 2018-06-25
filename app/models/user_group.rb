# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class UserGroup < ApplicationModel
  include HasGroupRelationDefinition

  self.table_name = 'groups_users'
end
