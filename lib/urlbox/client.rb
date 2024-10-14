require 'http'
require 'urlbox/errors'

module Urlbox
  class Client
    BASE_API_URL = 'https://api.urlbox.com/v1/'.freeze
    POST_END_POINT = 'render'.freeze

    def initialize(api_key: nil, api_secret: nil, api_host_name: nil)
      if api_key.nil? && ENV['URLBOX_API_KEY'].nil?
        raise Urlbox::Error, "Missing api_key or ENV['URLBOX_API_KEY'] not set"
      end

      @api_key = api_key || ENV['URLBOX_API_KEY']
      @api_secret = api_secret || ENV['URLBOX_API_SECRET']
      @base_api_url = init_base_api_url(api_host_name)
    end

    def get(options)
      HTTP.timeout(100).follow.get(generate_url(options))
    end

    def delete(options)
      processed_options, format = process_options(options)
      HTTP.delete("#{@base_api_url}#{@api_key}/#{format}?#{processed_options}")
    end

    def head(options)
      processed_options, format = process_options(options)
      HTTP.timeout(100)
          .follow
          .head("#{@base_api_url}#{@api_key}/#{format}?#{processed_options}")
    end

    def post(options)
      raise Urlbox::Error, Urlbox::Error.missing_api_secret_error_message if @api_secret.nil?

      unless options.key?(:webhook_url)
        warn('webhook_url not supplied, you will need to poll the statusUrl in order to get your result')
      end

      processed_options, _format = process_options_post_request(options)
      HTTP.timeout(5)
          .headers('Content-Type': 'application/json', 'Authorization': "Bearer #{@api_secret}")
          .post("#{@base_api_url}#{POST_END_POINT}", json: processed_options)
    end

    def generate_url(options)
      processed_options, format = process_options(options)

      if @api_secret
        "#{@base_api_url}" \
        "#{@api_key}/#{token(processed_options)}/#{format}" \
        "?#{processed_options}"
      else
        "#{@base_api_url}" \
        "#{@api_key}/#{format}" \
        "?#{processed_options}"
      end
    end

    # class methods to allow easy env var based usage
    class << self
      %i[delete head get post generate_url].each do |method|
        define_method(method) do |options|
          new.send(method, options)
        end
      end
    end

    private

    def init_base_api_url(api_host_name)
      if api_host_name
        "https://#{api_host_name}/"
      elsif ENV['URLBOX_API_HOST_NAME']
        ENV['URLBOX_API_HOST_NAME']
      else
        BASE_API_URL
      end
    end

    def prepend_schema(url)
      url.start_with?('http') ? url : "http://#{url}"
    end

    def process_options(options, url_encode_options: true)
      processed_options = options.transform_keys(&:to_sym)

      raise_key_error_if_missing_required_keys(processed_options)

      processed_options[:url] = process_url(processed_options[:url]) if processed_options[:url]
      processed_options[:format] = processed_options.fetch(:format, 'png')

      if url_encode_options
        [URI.encode_www_form(processed_options), processed_options[:format]]
      else
        [processed_options, processed_options[:format]]
      end
    end

    def process_options_post_request(options)
      process_options(options, url_encode_options: false)
    end

    def process_url(url)
      url_parsed = prepend_schema(url.strip)

      raise Urlbox::Error, "Invalid URL: #{url_parsed}" unless valid_url?(url_parsed)

      url_parsed
    end

    def raise_key_error_if_missing_required_keys(options)
      return unless options[:url].nil? && options[:html].nil?

      raise Urlbox::Error, 'Missing url or html entry in options'
    end

    def token(url_encoded_options)
      OpenSSL::HMAC.hexdigest('sha1', @api_secret.encode('UTF-8'), url_encoded_options.encode('UTF-8'))
    end

    def valid_url?(url)
      parsed_url = URI.parse(url)
      !parsed_url.host.nil? && parsed_url.host.include?('.')
    end
  end
end
