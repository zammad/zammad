# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class FormUpdaterIdType < BaseEnum
    description 'All available form updaters'

    build_class_list_enum FormUpdater::Updater.updaters
  end
end
