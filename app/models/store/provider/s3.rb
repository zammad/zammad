# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'aws-sdk-s3'

class Store::Provider::S3
  def self.add(data, sha)
    begin
      client.put_object({
                          body:   data,
                          bucket: bucket_name,
                          key:    sha,
                        })
    rescue Aws::S3::Errors::NoSuchBucket
      create_bucket
      add(data, sha)
    end
  end

  def self.get(sha)
    client.get_object({
                        bucket: bucket_name,
                        key:    sha,
                      }).body.read
  end

  def self.delete(sha)
    client.delete_object({
                           bucket: bucket_name,
                           key:    sha,
                         })
  end

  def self.client
    options = {
      force_path_style: Setting.get('storage_provider_s3_path_style_access'),
      region:           Setting.get('storage_provider_s3_region'),
      credentials:      Aws::Credentials.new(
        Setting.get('storage_provider_s3_access_key'),
        Setting.get('storage_provider_s3_secret_key')
      )
    }
    endpoint = Setting.get('storage_provider_s3_endpoint')
    options[:endpoint] = endpoint if !endpoint.empty?
    Aws::S3::Client.new(options)
  end

  def self.create_bucket
    client.create_bucket({
                           bucket: bucket_name
                         })
  end

  def self.bucket_name
    "zammad-#{Rails.env}"
  end
end
