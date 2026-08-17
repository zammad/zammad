# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service::AI::VectorDB
  class Reload < Service::AI::VectorDB::Base
    # Raised out of the reload when `abort_when` answers true: the run is obsolete, not broken -
    # the caller decides what its half-done work means, and nothing retries it.
    class Aborted < StandardError; end

    attr_reader :worker, :fresh, :abort_when

    # `fresh: true` is set by Rebuild, which reloads onto a just-created empty index — the per-record
    # membership search is then skipped (it would only ever come back empty).
    # `abort_when` is checked between records: a reload embeds one document at a time for however
    # long the knowledge base is, and a caller who learns mid-run that the result is obsolete stops
    # paying for it rather than finishing what a successor throws away.
    def initialize(worker: 0, fresh: false, abort_when: nil)
      @worker     = worker
      @fresh      = fresh
      @abort_when = abort_when
    end

    def execute
      ai_vector_db.ping!

      Models.all.keys.select { |model| model.include?(HasVectorIndex) }.each do |model|
        model.vector_index_reload(worker:, fresh:, abort_when:)
      end
    end
  end
end
