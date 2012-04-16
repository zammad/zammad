# clear cache
if Zammad::Application.config.cache_store[1] && File.directory?(Zammad::Application.config.cache_store[1])
  Rails.cache.clear
end

# to get rails caching working, load models
Dir.foreach("#{Rails.root}/app/models") do |model_name|
  require_dependency model_name unless model_name == '.' || model_name == '..' || model_name == '.gitkeep'
end 