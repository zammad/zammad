require "autodiscover/version"
require "nokogiri"
require "nori"
require "httpclient"
require "logging"

module Autodiscover
  Logging.logger["Autodiscover"].level = :info

  def self.logger
    Logging.logger["Autodiscover"]
  end

  def logger
    @logger ||= Logging.logger[self.class.name]
  end
end

require "autodiscover/errors"
require "autodiscover/client"
require "autodiscover/pox_request"
require "autodiscover/pox_response"
require "autodiscover/server_version_parser"
