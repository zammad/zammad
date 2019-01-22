FactoryBot.define do
  factory :'history/object', aliases: %i[history_object] do
    name { (ApplicationModel.descendants.select(&:any?).map(&:name) - History::Object.pluck(:name)).sample }
  end
end
