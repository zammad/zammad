require "faraday/middleware"
require "mime/types"
require 'tempfile'

module ZendeskAPI
  module Middleware
    module Request
      # @private
      class Upload < Faraday::Middleware
        def call(env)
          if env[:body]
            set_file(env[:body], :file, true)
            traverse_hash(env[:body])
          end

          @app.call(env)
        end

        private

        # Sets the proper file parameters :uploaded_data and :filename
        # If top_level, then it removes key and and sets the parameters directly on hash,
        # otherwise it adds the parameters to hash[key]
        def set_file(hash, key, top_level)
          return unless hash.key?(key)

          file = if hash[key].is_a?(Hash) && hash[key].key?(:file)
            hash[key].delete(:file)
          else
            hash.delete(key)
          end

          case file
          when File, Tempfile
            path = file.path
          when String
            path = file
          else
            if defined?(ActionDispatch) && file.is_a?(ActionDispatch::Http::UploadedFile)
              path = file.tempfile.path
              mime_type = file.content_type
            else
              warn "WARNING: Passed invalid filename #{file} of type #{file.class} to upload"
            end
          end

          if path
            if !top_level
              hash[key] ||= {}
              hash = hash[key]
            end

            mime_type ||= MIME::Types.type_for(path).first || "application/octet-stream"

            hash[:filename] ||= if file.respond_to?(:original_filename)
              file.original_filename
            else
              File.basename(path)
            end

            hash[:uploaded_data] = Faraday::UploadIO.new(path, mime_type, hash[:filename])
          end
        end

        # Calls #set_file on File instances or Hashes
        # of the format { :file => File (, :filename => ...) }
        def traverse_hash(hash)
          hash.keys.each do |key|
            if hash[key].is_a?(File)
              set_file(hash, key, false)
            elsif hash[key].is_a?(Hash)
              if hash[key].key?(:file)
                set_file(hash, key, false)
              else
                traverse_hash(hash[key])
              end
            end
          end
        end
      end
    end
  end
end
