# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::VectorIndexController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def sync
    # Enqueued before anything is checked, so that switching semantic search on records the intent
    # either way: the job re-reads the state when it runs, and a reconcile repairs it later even if
    # this one gives up (Service::AI::VectorDB::Reconcile).
    VectorIndexSyncJob.perform_later

    # The build happens in the background, so an Elasticsearch that cannot serve it would otherwise
    # only show up as a failed job in the health check, hours later - nothing tells the admin who
    # just switched it on. Not the setting's own validation: that would refuse to record the intent
    # over a condition which is none of its business and may pass again a minute later.
    return render json: { success: true } if Service::AI::VectorDB::Reachable.execute

    raise Exceptions::UnprocessableContent, __('The knowledge base index cannot be built. Please check that Elasticsearch is reachable and runs a supported version.')
  end
end
