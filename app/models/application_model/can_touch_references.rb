# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::CanTouchReferences
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

touch references by params

  Model.touch_reference_by_params(
    object: 'Ticket',
    o_id: 123,
  )

=end

    def touch_reference_by_params(data)
      object = data[:object].constantize.lookup(id: data[:o_id])
      return if !object

      object.touch # rubocop:disable Rails/SkipsModelValidations
    rescue => e
      logger.error e
    end
  end
end
