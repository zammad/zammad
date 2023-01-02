# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::Sources::DryRun::Payload < Sequencer::Unit::Import::Common::ImportJob::Payload::ToAttribute
  provides :ldap_config
end
