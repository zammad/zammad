# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::NormalizeEntry < Sequencer::Unit::Base
  uses :resource
  provides :resource

  def process

    state.provide(:resource) do
      empty = ActiveSupport::HashWithIndifferentAccess.new
      resource.each_with_object(empty) do |(key, values), normalized|
        normalized[key] = values.first
      end
    end
  end
end
