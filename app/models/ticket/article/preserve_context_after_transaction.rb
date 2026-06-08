# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Stores application handle info to use in after transaction callbacks.
#
# Usually object handling is wrapped with by setting ApplicationHandleInfo.current beforehand and unsetting it afterwards.
# This works for syncronous before/after model callbacks.
# However, when using after_commit callbacks, they're called later after ApplicationHandleInfo.current has been unset.
# This module stores the value that was set during action execution inside the instance.
# Then it's possible to get the value that was effective during the action in after_commit callbacks too.
module Ticket::Article::PreserveContextAfterTransaction
  extend ActiveSupport::Concern

  included do
    attr_accessor :application_handle_info_postmaster

    before_save :store_application_handle_info_postmaster
  end

  private

  def store_application_handle_info_postmaster
    self.application_handle_info_postmaster = ApplicationHandleInfo.postmaster?
  end
end
