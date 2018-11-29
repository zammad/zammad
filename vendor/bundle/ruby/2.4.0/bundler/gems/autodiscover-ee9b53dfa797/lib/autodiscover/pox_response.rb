module Autodiscover
  class PoxResponse

    attr_reader :response

    def initialize(response)
      raise ArgumentError, "Response must be an XML string" if(response.nil? || response.empty?)
      @response = Nori.new(parser: :nokogiri).parse(response)["Autodiscover"]["Response"]
    end

    def exchange_version
      ServerVersionParser.new(exch_proto["ServerVersion"]).exchange_version
    end

    def ews_url
      expr_proto["EwsUrl"]
    end

    def exch_proto
      @exch_proto ||= (response["Account"]["Protocol"].select{|p| p["Type"] == "EXCH"}.first || {})
    end

    def expr_proto
      @expr_proto ||= (response["Account"]["Protocol"].select{|p| p["Type"] == "EXPR"}.first || {})
    end

    def web_proto
      @web_proto ||= (response["Account"]["Protocol"].select{|p| p["Type"] == "WEB"}.first || {})
    end

  end
end
