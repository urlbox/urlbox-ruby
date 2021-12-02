require 'climate_control'
require 'minitest/autorun'
require 'urlbox_client'

class UrlboxClientTest < Minitest::Test
  # test_init
  def test_no_api_key_provided_and_env_var_not_set
    e = assert_raises Urlbox::UrlboxError do
      UrlboxClient.new
    end

    assert_equal e.message, "Missing api_key or ENV['URLBOX_API_KEY'] not set"
  end

  def test_no_api_key_provided_but_env_var_is_set
    env_var_api_key = 'ENV_VAR_KEY'

    ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
      urlbox_client = UrlboxClient.new

      # It doesn't throw an error and sets the api_key with the env var value
      assert_equal urlbox_client.instance_variable_get(:@api_key), env_var_api_key
    end
  end

  def test_api_key_provided_and_env_var_is_set
    env_var_api_key = 'ENV_VAR_KEY'
    param_api_key = 'PARAM_KEY'

    ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
      urlbox_client = UrlboxClient.new(api_key: param_api_key)

      # It sets the api_key with the param, not the env var, value
      assert_equal urlbox_client.instance_variable_get(:@api_key), param_api_key
    end
  end

  def test_no_api_secret_provided_but_env_var_is_set
    env_var_api_secret = 'ENV_VAR_SECRET'
    param_api_key = 'PARAM_KEY'

    ClimateControl.modify URLBOX_API_SECRET: env_var_api_secret do
      urlbox_client = UrlboxClient.new(api_key: param_api_key)

      assert_equal urlbox_client.instance_variable_get(:@api_secret), env_var_api_secret
    end
  end

  def test_api_secret_provided_and_env_var_is_set
    env_var_api_secret = 'ENV_VAR_SECRET'
    param_api_secret = 'PARAM_SECRET'
    param_api_key = 'PARAM_KEY'

    ClimateControl.modify URLBOX_API_SECRET: env_var_api_secret do
      urlbox_client = UrlboxClient.new(api_key: param_api_key, api_secret: param_api_secret)

      # It sets the api_secret with the param, not the env var, value
      assert_equal urlbox_client.instance_variable_get(:@api_secret), param_api_secret
    end
  end

  def test_api_host_name_provided
    param_api_key = 'PARAM_KEY'
    api_host_name = ['api-eu.urlbox.io', 'api-direct.urlbox.io'].sample

    urlbox_client = UrlboxClient.new(api_key: param_api_key, api_host_name: api_host_name)

    # Use the api_host_name
    assert_equal urlbox_client.instance_variable_get(:@base_api_url), "https://#{api_host_name}/"
  end

  def test_no_api_host_name_provided
    param_api_key = 'PARAM_KEY'

    urlbox_client = UrlboxClient.new(api_key: param_api_key)

    # Use the default BASE_API_URL
    assert_equal urlbox_client.instance_variable_get(:@base_api_url), UrlboxClient::BASE_API_URL
  end

  def test_no_api_host_name_provided_but_env_var_is_set
    param_api_key = 'PARAM_KEY'
    env_var_api_host_name = 'ENV_VAR_HOST_NAME'

    ClimateControl.modify URLBOX_API_HOST_NAME: env_var_api_host_name do
      urlbox_client = UrlboxClient.new(api_key: param_api_key)

      assert_equal env_var_api_host_name, urlbox_client.instance_variable_get(:@base_api_url)
    end
  end
end
