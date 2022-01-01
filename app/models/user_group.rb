# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class UserGroup < ApplicationModel
  include HasGroupRelationDefinition

  self.table_name = 'groups_users'
end
