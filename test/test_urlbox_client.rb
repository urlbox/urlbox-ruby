require 'minitest/autorun'
require 'urlbox_client'

class UrlboxClientTest < Minitest::Test
  # test_init
  def test_no_api_key_provided
    e = assert_raises ArgumentError do
      UrlboxClient.new
    end

    assert e.message.include?('missing keyword')
    assert e.message.include?('api_key')
  end

  def test_api_host_name_provided
    # TODO: replace with Faker
    api_key = 'foo'
    api_host_name = ['api-eu.urlbox.io', 'api-direct.urlbox.io'].sample

    urlbox_client = UrlboxClient.new(api_key: api_key, api_host_name: api_host_name)

    # Use the api_host_name
    assert_equal urlbox_client.instance_variable_get(:@base_api_url), "https://#{api_host_name}/"
  end

  def test_no_api_host_name_provided
    # TODO: replace with Faker
    api_key = 'foo'

    urlbox_client = UrlboxClient.new(api_key: api_key)

    # Use the default BASE_API_URL
    assert_equal urlbox_client.instance_variable_get(:@base_api_url), UrlboxClient::BASE_API_URL
  end
end
