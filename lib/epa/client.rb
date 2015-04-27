module Epa
  class Client
    def initialize(id, secret, api_type = :soap, options= {})
      @client = "Epa::#{api_type.to_s.camelize}::Client".constantize.new(id, secret, options)
    end

    def method_missing(method, *arguments, &block)
      @client.send method, *arguments
    end
  end
end