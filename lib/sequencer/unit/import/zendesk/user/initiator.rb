# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::User::Initiator < Sequencer::Unit::Base

  uses :resource
  provides :initiator

  def process
    state.provide(:initiator, initiator?)
  end

  private

  def initiator?
    return false if resource.email.blank?

    resource.email == Setting.get('import_zendesk_endpoint_username')
  end
end
