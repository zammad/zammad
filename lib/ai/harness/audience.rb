# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The boundary of a conversation: whom it serves and as whom it acts. It keeps no tool list: the tools it may offer at
# most are those that name it (Service::AI::Tool.audiences).
class AI::Harness::Audience
  attr_reader :name

  def initialize(name:)
    @name = name
  end

  # Its base instructions: whom the AI works for and what it may do for them (lib/ai/harness/prompts/audiences/).
  def instructions_template
    "audiences/#{name}"
  end

  # Human agents in Zammad; a conversation acts as its own user.
  HUMAN_AGENTS = new(name: :human_agents)

  ALL = [HUMAN_AGENTS].index_by(&:name).freeze

  def self.find(name)
    ALL[name.to_s.to_sym]
  end
end
