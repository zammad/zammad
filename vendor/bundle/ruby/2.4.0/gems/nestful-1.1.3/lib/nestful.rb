require 'nestful/version'
require 'nestful/exceptions'

module Nestful
  autoload :Endpoint,   'nestful/endpoint'
  autoload :Formats,    'nestful/formats'
  autoload :Connection, 'nestful/connection'
  autoload :Helpers,    'nestful/helpers'
  autoload :Mash,       'nestful/mash'
  autoload :Request,    'nestful/request'
  autoload :Response,   'nestful/response'
  autoload :Resource,   'nestful/resource'

  extend self

  def get(url, *args)
    Endpoint[url].get(*args)
  end

  def post(url, *args)
    Endpoint[url].post(*args)
  end

  def put(url, *args)
    Endpoint[url].put(*args)
  end

  def delete(url, *args)
    Endpoint[url].delete(*args)
  end

  def request(url, *args)
    Endpoint[url].request(*args)
  end
end