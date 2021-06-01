# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

FactoryBot.define do
  factory :'history/object', aliases: %i[history_object] do
    name { (ApplicationModel.descendants.select(&:any?).map(&:name) - History::Object.pluck(:name)).sample }
  end
end
