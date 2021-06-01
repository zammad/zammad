# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::HasExternalSync
  extend ActiveSupport::Concern

  included do
    after_destroy :external_sync_destroy
  end

  def external_sync_destroy
    ExternalSync.where(
      object: self.class.to_s,
      o_id:   id,
    ).destroy_all
  end
end
