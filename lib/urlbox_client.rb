class UrlboxClient
  BASE_API_URL = "https://api.urlbox.io/v1/"
  POST_END_POINT = "render"

  def initialize(api_key:, api_secret: nil, api_host_name: nil)
    @api_key = api_key
    @api_secret = api_secret
    @base_api_url = init_base_api_url(api_host_name)
  end

  private

  def init_base_api_url(api_host_name)
    if api_host_name.nil?
      BASE_API_URL
    else
      "https://#{api_host_name}/"
    end
  end
end
