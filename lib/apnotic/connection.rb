require 'net-http2'
require 'openssl'

module Apnotic

  APPLE_DEVELOPMENT_SERVER_URI = "https://api.development.push.apple.com:443"
  APPLE_PRODUCTION_SERVER_URI  = "https://api.push.apple.com:443"

  class Connection
    attr_reader :url, :cert_path

    class << self
      def development(options={})
        options.merge!(url: APPLE_DEVELOPMENT_SERVER_URI)
        new(options)
      end
    end

    def initialize(options={})
      @url       = options[:url] || APPLE_PRODUCTION_SERVER_URI
      @cert_path = options[:cert_path]
      @cert_pass = options[:cert_pass]

      raise "Cert file not found: #{@cert_path}" unless @cert_path && File.exist?(@cert_path)

      @client = NetHttp2::Client.new(@url, ssl_context: ssl_context)
    end

    def push(notification, options={})
      request  = Apnotic::Request.new(notification)
      response = @client.post(request.path, request.body, request.headers, timeout: options[:timeout])
      Apnotic::Response.new(headers: response.headers, body: response.body) if response
    end

    def close
      @client.close
    end

    private

    def ssl_context
      @ssl_context ||= begin
        ctx         = OpenSSL::SSL::SSLContext.new
        certificate = File.read(@cert_path)
        ctx.key     = OpenSSL::PKey::RSA.new(certificate, @cert_pass)
        ctx.cert    = OpenSSL::X509::Certificate.new(certificate)
        ctx
      end
    end
  end
end
