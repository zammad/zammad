FactoryBot.define do
  factory :'tag/object', aliases: %i[tag_object] do
    name { (ApplicationModel.descendants.select(&:any?).map(&:name) - Tag::Object.pluck(:name)).sample }
  end
end
