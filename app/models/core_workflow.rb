# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow < ApplicationModel
  include ChecksClientNotification
  include CoreWorkflow::Assets

  default_scope { order('priority ASC, name ASC, id ASC') }
  scope :active, -> { where(active: true) }
  scope :changeable, -> { where(changeable: true) }
  scope :object, ->(object) { where(object: [object, nil]) }

  store :preferences
  store :condition_saved
  store :condition_selected
  store :perform

  validates :name, presence: true

  def self.perform(payload:, user:, assets: {}, assets_in_result: true, result: {})
    CoreWorkflow::Result.new(payload: payload, user: user, assets: assets, assets_in_result: assets_in_result, result: result).run
  rescue => e
    return {} if e.is_a?(ArgumentError)
    raise e if !Rails.env.production?

    Rails.logger.error 'Error performing Core Workflow engine.'
    Rails.logger.error e
    {}
  end
end
