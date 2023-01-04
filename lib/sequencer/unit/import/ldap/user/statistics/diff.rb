# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Statistics::Diff < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

  uses :instance, :associations, :signup_role_ids

  def process
    state.provide(:statistics_diff) do
      add_role_ids(diff)
    end
  end

  private

  def add_role_ids(statistics)
    return statistics if instance.blank?
    return statistics if associations.blank?

    # add the parent role_ids hash
    # so we can fill it
    statistics[:role_ids] = {}

    associations[:role_ids] ||= signup_role_ids

    # add the diff for each role_id the user is assigned to
    associations[:role_ids].each_with_object(statistics) do |role_id, result|
      result[:role_ids][role_id] = diff
    end
  end
end
