# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::ImportJob::Payload::ToAttribute < Sequencer::Unit::Base

  uses :import_job

  def process
    provides = self.class.provides
    raise "Can't find any provides for #{self.class.name}" if provides.blank?

    provides.each do |attribute|
      state.provide(attribute, import_job.payload[attribute])
    end
  end
end
