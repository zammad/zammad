# clear cache
if Zammad::Application.config.cache_store[1] && File.directory?(Zammad::Application.config.cache_store[1])
  puts 'clear cache...'
  Rails.cache.clear
end