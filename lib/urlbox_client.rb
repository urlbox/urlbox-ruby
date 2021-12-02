require 'urlbox/errors'

class UrlboxClient
  BASE_API_URL = 'https://api.urlbox.io/v1/'.freeze
  POST_END_POINT = 'render'.freeze

  def initialize(api_key: nil, api_secret: nil, api_host_name: nil)
    if api_key.nil? && ENV['URLBOX_API_KEY'].nil?
      raise Urlbox::UrlboxError, "Missing api_key or ENV['URLBOX_API_KEY'] not set"
    end

    @api_key = api_key || ENV['URLBOX_API_KEY']
    @api_secret = api_secret || ENV['URLBOX_API_SECRET']
    @base_api_url = init_base_api_url(api_host_name)
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
end
