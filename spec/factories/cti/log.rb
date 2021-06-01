# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'cti/log', aliases: %i[cti_log] do
    direction { %w[in out].sample }
    state     { 'newCall' }
    from      { '4930609854180' }
    to        { '4930609811111' }
    call_id   { (Cti::Log.pluck(:call_id).map(&:to_i).max || 0).next } # has SQL UNIQUE constraint
    done      { false }

    trait :with_preferences do
      preferences { Cti::CallerId.get_comment_preferences(from, 'from')&.last }
    end
  end
end
