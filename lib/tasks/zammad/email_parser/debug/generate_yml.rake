# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do
  namespace :email_parser do
    namespace :debug do

      desc 'Build a sample mail from the given path'
      task :generate_yml, [:file_path] => :environment do |_task, args|
        file_path = args[:file_path]

        current_max_name = Dir
          .glob('test/data/mail/mail*.yml')
          .filter_map do |elem|
            next if !elem.match(%r{mail(\d+)\.yml})

            $1.to_i
          end
          .max

        new_name = "mail#{current_max_name + 1}"

        target_box_file = "test/data/mail/#{new_name}.box"
        target_yml_file = "test/data/mail/#{new_name}.yml"

        FileUtils.copy(file_path, target_box_file)

        parsed = Channel::EmailParser.prepare_sample_mail(File.read(target_box_file))

        File.write(target_yml_file, parsed.to_yaml)

        puts 'Please bump tests count at spec/models/channel/email_parser_spec.rb!'
      end
    end

  end
end
