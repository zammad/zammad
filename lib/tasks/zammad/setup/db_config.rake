namespace :zammad do

  namespace :setup do

    desc 'Copies the database config template file to config/database.yml'
    task :db_config do

      config_dir  = Rails.root.join('config')
      template    = config_dir.join('database', 'database.yml')
      destination = config_dir.join('database.yml')

      raise Errno::ENOENT, "#{template} not found" unless File.exist?(template)

      if File.exist?(destination)
        next if FileUtils.identical?(template, destination)

        printf 'config/database.yml: File exists. Overwrite? [y/N] '
        next if !STDIN.gets.chomp.casecmp('y').zero?
      end

      FileUtils.cp(template, destination)
    end
  end
end
