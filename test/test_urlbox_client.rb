require 'climate_control'
require 'minitest/autorun'
require 'urlbox/client'
require 'webmock/minitest'

module Urlbox
  class ClientTest < Minitest::Test
    # test_init
    def test_no_api_key_provided_and_env_var_not_set
      e = assert_raises Urlbox::Error do
        Urlbox::Client.new
      end

      assert_equal e.message, "Missing api_key or ENV['URLBOX_API_KEY'] not set"
    end

    def test_no_api_key_provided_but_env_var_is_set
      env_var_api_key = 'ENV_VAR_KEY'

      ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
        urlbox_client = Urlbox::Client.new

        # It doesn't throw an error and sets the api_key with the env var value
        assert_equal urlbox_client.instance_variable_get(:@api_key), env_var_api_key
      end
    end

    def test_api_key_provided_and_env_var_is_set
      env_var_api_key = 'ENV_VAR_KEY'
      param_api_key = 'PARAM_KEY'

      ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
        urlbox_client = Urlbox::Client.new(api_key: param_api_key)

        # It sets the api_key with the param, not the env var, value
        assert_equal urlbox_client.instance_variable_get(:@api_key), param_api_key
      end
    end

    def test_no_api_secret_provided_but_env_var_is_set
      env_var_api_secret = 'ENV_VAR_SECRET'
      param_api_key = 'PARAM_KEY'

      ClimateControl.modify URLBOX_API_SECRET: env_var_api_secret do
        urlbox_client = Urlbox::Client.new(api_key: param_api_key)

        assert_equal urlbox_client.instance_variable_get(:@api_secret), env_var_api_secret
      end
    end

    def test_api_secret_provided_and_env_var_is_set
      env_var_api_secret = 'ENV_VAR_SECRET'
      param_api_secret = 'PARAM_SECRET'
      param_api_key = 'PARAM_KEY'

      ClimateControl.modify URLBOX_API_SECRET: env_var_api_secret do
        urlbox_client = Urlbox::Client.new(api_key: param_api_key, api_secret: param_api_secret)

        # It sets the api_secret with the param, not the env var, value
        assert_equal urlbox_client.instance_variable_get(:@api_secret), param_api_secret
      end
    end

    def test_api_host_name_provided
      param_api_key = 'PARAM_KEY'
      api_host_name = ['api-eu.urlbox.io', 'api-direct.urlbox.io'].sample

      urlbox_client = Urlbox::Client.new(api_key: param_api_key, api_host_name: api_host_name)

      # Use the api_host_name
      assert_equal urlbox_client.instance_variable_get(:@base_api_url), "https://#{api_host_name}/"
    end

    def test_no_api_host_name_provided
      param_api_key = 'PARAM_KEY'

      urlbox_client = Urlbox::Client.new(api_key: param_api_key)

      # Use the default BASE_API_URL
      assert_equal urlbox_client.instance_variable_get(:@base_api_url), Urlbox::Client::BASE_API_URL
    end

    def test_no_api_host_name_provided_but_env_var_is_set
      param_api_key = 'PARAM_KEY'
      env_var_api_host_name = 'ENV_VAR_HOST_NAME'

      ClimateControl.modify URLBOX_API_HOST_NAME: env_var_api_host_name do
        urlbox_client = Urlbox::Client.new(api_key: param_api_key)

        assert_equal env_var_api_host_name, urlbox_client.instance_variable_get(:@base_api_url)
      end
    end

    # Test get
    def test_successful_get_request
      param_api_key = 'KEY'
      options = { url: 'https://www.example.com' }

      stub_request(:get, "https://api.urlbox.io/v1/#{param_api_key}/png?format=png&url=https://www.example.com")
        .to_return(status: 200, body: '', headers: { 'content-type': 'image/png' })

      urlbox_client = Urlbox::Client.new(api_key: param_api_key)

      response = urlbox_client.get(options)

      assert response.status == 200
      assert response.headers['Content-Type'].include?('png')
    end

    def test_successful_get_request_no_schema_url
      param_api_key = 'KEY'
      options = { url: 'www.example.com' }

      stub_request(:get, "https://api.urlbox.io/v1/#{param_api_key}/png?format=png&url=http://www.example.com")
        .to_return(status: 200, body: '', headers: {})

      urlbox_client = Urlbox::Client.new(api_key: param_api_key)

      response = urlbox_client.get(options)

      assert response.status == 200
    end

    def test_unsuccessful_get_invalid_url
      param_api_key = 'KEY'
      options = { url: 'FOO' }

      urlbox_client = Urlbox::Client.new(api_key: param_api_key)

      e = assert_raises Urlbox::Error do
        urlbox_client.get(options)
      end

      assert_equal e.message, 'Invalid URL: http://FOO'
    end

    def test_unsuccessful_get_missing_url_or_html_entry_in_options
      param_api_key = 'KEY'
      options = { format: 'png' }

      urlbox_client = Urlbox::Client.new(api_key: param_api_key)

      e = assert_raises Urlbox::Error do
        urlbox_client.get(options)
      end

      assert_equal e.message, 'Missing url or html entry in options'
    end

    def test_successful_get_request_authenticated
      api_key = 'KEY'
      api_secret = 'SECRET'
      options = { url: 'https://www.example.com', format: 'png' }
      url_encoded_options = URI.encode_www_form(options)
      token = OpenSSL::HMAC.hexdigest('sha1', api_secret.encode('UTF-8'), url_encoded_options.encode('UTF-8'))

      stub_request(:get, "https://api.urlbox.io/v1/KEY/#{token}/png?format=png&url=https://www.example.com")
        .to_return(status: 200, body: '', headers: { 'content-type': 'image/png' })

      urlbox_client = Urlbox::Client.new(api_key: api_key, api_secret: api_secret)

      response = urlbox_client.get(options)

      assert response.status == 200
      assert response.headers['Content-Type'].include?('png')
    end

    def test_successful_get_request_options_with_string_keys
      param_api_key = 'KEY'
      options = { 'url' => 'https://www.example.com' }

      stub_request(:get, "https://api.urlbox.io/v1/#{param_api_key}/png?format=png&url=https://www.example.com")
        .to_return(status: 200, body: '', headers: { 'content-type': 'image/png' })

      urlbox_client = Urlbox::Client.new(api_key: param_api_key)

      response = urlbox_client.get(options)

      assert response.status == 200
      assert response.headers['Content-Type'].include?('png')
    end

    def test_get_with_header_array_in_options
      api_key = 'KEY'
      options = {
        url: 'https://www.example.com',
        header: ["x-my-first-header=somevalue", "x-my-second-header=someothervalue"]
      }

      urlbox_client = Urlbox::Client.new(api_key: api_key)

      stub_request(:get, "https://api.urlbox.io/v1/KEY/png?format=png&header=x-my-second-header=someothervalue&url=https://www.example.com")
        .to_return(status: 200, body: "", headers: {})

      response = urlbox_client.get(options)

      assert response.status == 200
    end

    # test delete
    def test_delete_request
      api_key = 'KEY'
      options = { url: 'https://www.example.com' }

      stub_request(:delete, 'https://api.urlbox.io/v1/KEY/png?format=png&url=https://www.example.com')
        .to_return(status: 200, body: '', headers: {})

      urlbox_client = Urlbox::Client.new(api_key: api_key)

      response = urlbox_client.delete(options)

      assert response.status == 200
    end

    # test head
    def test_head_request
      api_key = 'KEY'
      format = %w[png jpg jpeg avif webp pdf svg html].sample
      url = 'https://www.example.com'

      options = {
        url: url,
        format: format,
        full_page: [true, false].sample,
        width: [500, 700].sample
      }

      stub_request(:head, "https://api.urlbox.io/v1/#{api_key}/#{format}?format=#{format}&full_page=#{options[:full_page]}&url=#{url}&width=#{options[:width]}")
        .to_return(status: 200, body: '', headers: {})

      urlbox_client = Urlbox::Client.new(api_key: api_key)

      response = urlbox_client.head(options)

      assert response.status == 200
    end

    # test post
    def test_post_request_successful
      api_key = 'KEY'
      api_secret = 'SECRET'
      options = {
        url: 'https://www.example.com',
        webhook_url: 'https://www.example.com/webhook'
      }

      stub_request(:post, 'https://api.urlbox.io/v1/render')
        .with(
          body: "{\"url\":\"https://www.example.com\",\"webhook_url\":\"https://www.example.com/webhook\",\"format\":\"png\"}",
          headers: {
            'Authorization' => 'Bearer SECRET',
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 201)

      urlbox_client = Urlbox::Client.new(api_key: api_key, api_secret: api_secret)

      response = urlbox_client.post(options)

      assert response.status == 201
    end

    def test_post_request_successful_warning_missing_webhook_url
      api_key = 'KEY'
      api_secret = 'SECRET'
      options = { url: 'https://www.example.com' }

      stub_request(:post, 'https://api.urlbox.io/v1/render')
        .with(
          body: "{\"url\":\"https://www.example.com\",\"format\":\"png\"}",
          headers: {
            'Authorization' => 'Bearer SECRET',
            'Content-Type' => 'application/json'
          }
        ).to_return(status: 201)

      urlbox_client = Urlbox::Client.new(api_key: api_key, api_secret: api_secret)

      response = urlbox_client.post(options)

      assert response.status == 201
      # Wasn't able to test the warning message
    end

    def test_post_request_unsuccessful_missing_api_secret
      api_key = 'KEY'
      options = {
        url: 'https://www.example.com',
        webhook_url: 'https://www.example.com/webhook'
      }

      urlbox_client = Urlbox::Client.new(api_key: api_key)

      e = assert_raises Urlbox::Error do
        urlbox_client.post(options)
      end

      assert e.message.include? 'Missing api_secret'
    end

    # test generate_url
    def test_generate_url_with_only_api_key
      api_key = 'KEY'
      options = { url: 'https://www.example.com', format: 'png' }

      urlbox_client = Urlbox::Client.new(api_key: api_key)

      urlbox_url = urlbox_client.generate_url(options)

      assert_equal 'https://api.urlbox.io/v1/KEY/png?url=https%3A%2F%2Fwww.example.com&format=png', urlbox_url
    end

    def test_generate_url_with_api_key_and_secret
      api_key = 'KEY'
      api_secret = 'SECRET'
      options = { url: 'https://www.example.com', format: 'png' }
      url_encoded_options = URI.encode_www_form(options)
      token = OpenSSL::HMAC.hexdigest('sha1', api_secret.encode('UTF-8'), url_encoded_options.encode('UTF-8'))

      urlbox_client = Urlbox::Client.new(api_key: api_key, api_secret: api_secret)

      urlbox_url = urlbox_client.generate_url(options)

      assert_equal "https://api.urlbox.io/v1/KEY/#{token}/png?url=https%3A%2F%2Fwww.example.com&format=png", urlbox_url
    end

    # test module like methods
    # get
    def test_successful_class_get_request
      env_var_api_key = 'ENV_VAR_KEY'
      options = { url: 'https://www.example.com' }

      ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
        stub_request(:get, "https://api.urlbox.io/v1/#{env_var_api_key}/png?format=png&url=https://www.example.com")
          .to_return(status: 200, body: '', headers: { 'content-type': 'image/png' })

        response = Urlbox::Client.get(options)

        assert response.status == 200
        assert response.headers['Content-Type'].include?('png')
      end
    end

    # delete
    def test_successful_class_delete_request
      env_var_api_key = 'ENV_VAR_KEY'
      options = { url: 'https://www.example.com' }

      ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
        stub_request(:delete, "https://api.urlbox.io/v1/#{env_var_api_key}/png?format=png&url=https://www.example.com")
          .to_return(status: 200, body: '', headers: { 'content-type': 'image/png' })

        response = Urlbox::Client.delete(options)

        assert response.status == 200
        assert response.headers['Content-Type'].include?('png')
      end
    end

    # head
    def test_successful_class_head_request
      env_var_api_key = 'ENV_VAR_KEY'
      options = { url: 'https://www.example.com' }

      ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
        stub_request(:head, "https://api.urlbox.io/v1/#{env_var_api_key}/png?format=png&url=https://www.example.com")
          .to_return(status: 200, body: '', headers: { 'content-type': 'image/png' })

        response = Urlbox::Client.head(options)

        assert response.status == 200
        assert response.headers['Content-Type'].include?('png')
      end
    end

    # post
    def test_successful_class_post_request
      api_key = 'KEY'
      api_secret = 'SECRET'
      options = {
        url: 'https://www.example.com',
        webhook_url: 'https://www.example.com/webhook'
      }

      ClimateControl.modify URLBOX_API_KEY: api_key, URLBOX_API_SECRET: api_secret do
        stub_request(:post, 'https://api.urlbox.io/v1/render')
          .with(
            body: "{\"url\":\"https://www.example.com\",\"webhook_url\":\"https://www.example.com/webhook\",\"format\":\"png\"}",
            headers: {
              'Authorization' => 'Bearer SECRET',
              'Content-Type' => 'application/json'
            }
          ).to_return(status: 201)

        response = Urlbox::Client.post(options)

        assert response.status == 201
      end
    end

    # generate_url
    def test_successful_class_generate_url
      env_var_api_key = 'KEY'
      options = { url: 'https://www.example.com' }

      ClimateControl.modify URLBOX_API_KEY: env_var_api_key do
        urlbox_url = Urlbox::Client.generate_url(options)

        assert_equal 'https://api.urlbox.io/v1/KEY/png?url=https%3A%2F%2Fwww.example.com&format=png', urlbox_url
      end
    end
  end
end
