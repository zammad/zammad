# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How well the answers of a search by meaning fit its query, said to the model: `covered` when the best answer reaches
#   the upper value and stands out by the margin, `weak` when answers were found but none clearly fits, `none` without
#   any. The label never removes an answer; the model judges the answers itself.
#
# The values belong to the embedding model, whose scores have a scale of their own, so a model nobody measured gets no
#   verdict at all.
class Service::AI::Tool::SearchKnowledgeBase::Coverage
  # Elasticsearch's cosine scores, (1 + cos) / 2, measured on made-up answers with queries as models write them. An
  #   answer in another language than the query scores a few points lower than one in its language, so answers are
  #   listed from a lower value than the one that makes a result `covered`.
  VALUES = {
    'bge-m3' => { listed: 0.78, covered: 0.80, margin: 0.01 },
  }.freeze

  attr_reader :listed, :covered, :margin

  # @param model [String, nil] the embedding model, e.g. "bge-m3" or Ollama's "bge-m3:latest"
  # @return [Service::AI::Tool::SearchKnowledgeBase::Coverage, nil] nil for a model without measured values
  def self.for(model)
    values = VALUES[model.to_s.split(':').first]
    return if values.nil?

    new(**values)
  end

  def initialize(listed:, covered:, margin:)
    @listed  = listed
    @covered = covered
    @margin  = margin
  end

  # @param scores [Array<Float>] one score per listed answer
  # @return [String] covered, weak or none
  def of(scores)
    best, second = scores.sort.reverse

    return 'none' if best.nil?
    return 'weak' if best < covered
    return 'covered' if second.nil? || (best - second) / best >= margin

    'weak'
  end
end
