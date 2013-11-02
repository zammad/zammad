# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'net/http'
require 'net/https'
require 'net/ftp'
require 'tempfile'

class UserAgent

=begin

http/https/ftp calls

  result = UserAgent.request( 'ftp://host/some_dir/some_file.bin' )

  result = UserAgent.request( 'http://host/some_dir/some_file.bin' )

  result = UserAgent.request( 'https://host/some_dir/some_file.bin' )

  result = UserAgent.request( 'http://host/some_dir/some_file.bin', { :method => 'post', :data => { :param1 => 123 } } )

returns

  result # result object

=end


  def self.request(url, options = {})

    uri = URI.parse(url)
    case uri.scheme.downcase
    when /ftp/
      ftp(uri, options)
    when /http|https/
      http(uri, options, 10)
    end

  end

  private
    def self.http(uri, options, count)

      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme =~ /https/i
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      if !options[:method] || options[:method] =~ /^get$/i
        request = Net::HTTP::Get.new(uri.request_uri)

        # http basic auth (if needed)
        if options[:user] && options[:user] != '' && options[:password] && options[:password] != ''
          request.basic_auth user, password
        end

        begin
          response = http.request(request)
        rescue Exception => e
          return Result.new(
            :error   => e.inspect,
            :success => false,
            :code    => 0,
          )
        end
      elsif options[:method] =~ /^post$/i
        request = Net::HTTP::Post.new(uri.request_uri)

        # http basic auth (if needed)
        if options[:user] && options[:user] != '' && options[:password] && options[:password] != ''
          request.basic_auth user, password
        end

        begin
          request.set_form_data( options[:data] )
          response = http.request(request)
        rescue Exception => e
          return Result.new(
            :error   => e.inspect,
            :success => false,
            :code    => 0,
          )
        end
      end

      if !response
        return Result.new(
          :error   => "Can't connect to #{uri.to_s}, got no response!",
          :success => false,
          :code    => 0,
        )
      end

      case response
      when Net::HTTPNotFound
        return Result.new(
          :error   => "No such file #{uri.to_s}, 404!",
          :success => false,
          :code    => response.code,
        )

      when Net::HTTPClientError
        return Result.new(
          :error   => "Client Error: #{response.inspect}!",
          :success => false,
          :code    => response.code,
        )

      when Net::HTTPRedirection
        raise "Too many redirections for the original URL, halting." if count <= 0
        url = response["location"]
        uri = URI.parse(url)
        return http(uri, options, count - 1)

      when Net::HTTPOK
        return Result.new(
          :body         => response.body,
          :content_type => response['Content-Type'],
          :success      => true,
          :code         => response.code,
        )
      end

      raise "Unknown method '#{option[:method]}'"
    end

    def self.ftp(uri,options)
      host       = uri.host
      filename   = File.basename(uri.path)
      remote_dir = File.dirname(uri.path)

      temp_file = Tempfile.new("download-#{filename}")
      temp_file.binmode

      begin
        Net::FTP.open(host) do |ftp|
          ftp.passive = true
          if options[:user] && options[:password]
            ftp.login( options[:user], options[:password] )
          else
            ftp.login
          end
          ftp.chdir(remote_dir) unless remote_dir == '.'

          begin
            ftp.getbinaryfile( filename, temp_file )
          rescue => e
            return Result.new(
              :error   => e.inspect,
              :success => false,
              :code    => 550,
            )
          end
        end
      rescue => e
        return Result.new(
          :error   => e.inspect,
          :success => false,
        )
      end

      contents = temp_file.read
      temp_file.close
      Result.new(
        :body    => contents,
        :success => true,
        :code    => 200,
      )
    end

  class Result
    def initialize(options)
      @success      = options[:success]
      @body         = options[:body]
      @code         = options[:code]
      @content_type = options[:content_type]
      @error        = options[:error]
    end
    def error
      @error
    end
    def success?
      @success
    end
    def body
      @body
    end
    def code
      @code
    end
    def content_type
      @content_type
    end
  end
end
