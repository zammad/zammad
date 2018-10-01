namespace :zammad do

  namespace :ci do

    namespace :test do

      desc 'Stops all of Zammads services and exists the rake task with exit code 1'
      task fail: %i[zammad:ci:test:stop] do
        abort('Abort further test processing')
      end
    end
  end
end
