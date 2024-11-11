module Synology
  class Configuration
    attr_accessor :host, :port, :username, :password, :use_cookies, :https, :api_endpoints, :api_endpoint, :parse_errors

    def initialize
      @api_endpoints = nil
      @api_endpoint = nil
      # Syno default port
      @port = 5000
      @https = false
      @use_cookies = true
      @parse_errors = true
    end

    def base_url
      "#{https ? 'https' : 'http'}://#{host}:#{port}"
    end
  end
end
