# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class TaskbarInputType < Gql::Types::BaseInputObject

    description 'The taskbar entry.'

    argument :name, String, description: 'File name.'
    argument :type, String, required: false, description: "File's content-type."
    argument :content, Gql::Types::BinaryStringType, required: false, description: 'File content'
  end
end
