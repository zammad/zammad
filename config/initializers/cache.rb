# clear cache
Rails.cache.clear

# to get rails caching working, load models
Dir.foreach("#{Rails.root}/app/models") do |model_name|
  require_dependency model_name unless model_name == '.' || model_name == '..' || model_name == '.gitkeep'
end 