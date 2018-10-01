namespace :zammad do

  namespace :flush do

    desc 'Flushes all caches'
    task :cache do
      FileUtils.rm_rf(Rails.root.join('tmp', 'cache*'))
    end
  end
end
