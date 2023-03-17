# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Organization::Mapping < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource

  def process
    provide_mapped do
      {
        name:              resource['name'],
        domain:            domain,
        domain_assignment: domain.present?,
      }
    end
  end

  private

  def domain
    @domain ||= begin
      primary_domain = resource['domains']&.detect { |item| item['is_primary'] }
      primary_domain&.fetch('domain')
    end
  end
end
