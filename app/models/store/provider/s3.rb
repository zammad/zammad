# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'aws-sdk-s3'

module Store::Provider::S3

  class Store::Provider::S3::Error < StandardError; end

  class << self

    def add(data, sha)
      if data.bytesize > Store::Provider::S3::Config.max_chunk_size
        return upload(data, sha)
      end

      request(:put_object, key: sha, body: data)

      true
    end

    def client
      Certificate::ApplySSLCertificates.ensure_fresh_ssl_context

      @client.presence ||
        (Store::Provider::S3::Config.apply && @client = Aws::S3::Client.new)
    end

    def delete(sha)
      request(:delete_object, key: sha)

      true
    end

    def get(sha)
      object = request(:get_object, key: sha)
      object.body.binmode.read
    end

    def upload(data, sha)
      begin
        id    = Store::Provider::S3::Upload.create(sha)
        parts = Store::Provider::S3::Upload.process(data, sha, id)

        Store::Provider::S3::Upload.complete(sha, parts, id)
      rescue => e
        log_and_raise(e)
      end

      true
    end

    def url(sha, expires_in: 3600)
      object = Aws::S3::Object.new(bucket_name: bucket, key: sha, client: client)
      object.presigned_url(:get, expires_in: expires_in)
    rescue => e
      log_and_raise(e)
    end

    def ping?
      return false if !client

      client.head_bucket(bucket: bucket)
      true
    rescue => e
      Rails.logger.error { "#{name}: #{e.message}" }
      false
    end

    def ping!
      raise Store::Provider::S3::Error, __('Simple Storage Service not reachable.') if !ping?
    end

    def reset
      @client = nil
      Store::Provider::S3::Config.reset

      true
    end

    private

    def bucket
      Store::Provider::S3::Config.bucket
    end

    def log_and_raise(error)
      Rails.logger.error { "#{name}: #{error.message}" }
      raise Store::Provider::S3::Error, __('Simple Storage Service malfunction. Please contact your Zammad administrator.')
    end

    def request(method, **)
      client.send(method, bucket: bucket, **)
    rescue => e
      log_and_raise(e)
    end

  end
end
