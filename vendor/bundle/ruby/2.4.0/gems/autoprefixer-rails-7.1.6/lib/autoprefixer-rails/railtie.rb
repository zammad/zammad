require 'yaml'

begin
  module AutoprefixedRails
    class Railtie < ::Rails::Railtie
      rake_tasks do |app|
        require 'rake/autoprefixer_tasks'
        Rake::AutoprefixerTasks.new( config ) if defined? app.assets
      end

      if config.respond_to?(:assets) and not config.assets.nil?
        config.assets.configure do |env|
          AutoprefixerRails.install(env, config)
        end
      else
        initializer :setup_autoprefixer, group: :all do |app|
          if defined? app.assets and not app.assets.nil?
            AutoprefixerRails.install(app.assets, config)
          end
        end
      end

      # Read browsers requirements from application or engine config
      def config
        params = {}

        roots.each do |root|
          file = File.join(root, 'config/autoprefixer.yml')

          if File.exist?(file)
            parsed = ::YAML.load_file(file)
            next unless parsed
            params = parsed

            break
          end
        end

        params = params.symbolize_keys
        params[:env] ||= Rails.env.to_s
        params
      end

      def roots
        [Rails.application.root] + Rails::Engine.subclasses.map(&:root)
      end
    end
  end
rescue LoadError
end
