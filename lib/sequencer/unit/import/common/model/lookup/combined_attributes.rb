# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Lookup::CombinedAttributes < Sequencer::Unit::Import::Common::Model::Lookup::Attributes
  def existing_instance
    @existing_instance ||= begin
      filters = {}

      Array(attributes).each do |attribute|
        value = mapped[attribute]
        next if value.blank?

        filters[attribute] = value
      end

      if filters.present?
        model_class.find_by(filters)
      end
    end
  end
end
