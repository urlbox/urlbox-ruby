require 'climate_control'
require 'minitest/autorun'
require 'urlbox/webhook_validator'
require 'webmock/minitest'

module Urlbox
  class WebhookValidatorTest < Minitest::Test
    # helper functions

    def header_signature
      "t=#{timestamp_one_minute_ago},sha256=1e1b3c7f6b5f60f7b44ed1a85e653769ecf0c41ec5c7e8c131fc1a20357cc2b1"
    end

    def timestamp_one_minute_ago
      (Time.now - 60).to_i
    end

    def payload
      {
        "event": "render.succeeded",
        "renderId": "794383cd-b09e-4aef-a12b-fadf8aad9d63",
        "result": {
          "renderUrl": "https://renders.urlbox.io/urlbox1/renders/61431b47b8538a00086c29dd/2021/11/24/bee42850-bab6-43c6-bd9d-e614581d31b4.png"
        },
        "meta": {
          "startTime": "2021-11-24T16:49:48.307Z",
          "endTime": "2021-11-24T16:49:53.659Z"
        }
      }
    end

    def webhook_secret
      "WEBHOOK_SECRET"
    end
    # helper functions - end

    def test_call_valid_webhook
      # Dynamically generate header signature to make the crypto comparision pass
      payload_json_string = JSON.dump(payload)

      signature_generated =
        OpenSSL::HMAC.hexdigest('sha256',
                                webhook_secret.encode('UTF-8'),
                                "#{timestamp_one_minute_ago}.#{payload_json_string.encode('UTF-8')}")

      header_signature = "t=#{timestamp_one_minute_ago},sha256=#{signature_generated}"

      assert Urlbox::WebhookValidator.call(header_signature, payload, webhook_secret)
    end

    def test_call_invalid_signature
      header_signature = "INVALID_SIGNATURE"

      assert_raises Urlbox::InvalidHeaderSignatureError do
        Urlbox::WebhookValidator.call(header_signature, payload, webhook_secret)
      end
    end

    def test_call_invalid_hash_mismatch
      header_signature = "t=#{timestamp_one_minute_ago},sha256=930ee08957512f247e289703ac951fc60da1e2d12919bfd518d90513b0687ee0"

      e = assert_raises Urlbox::InvalidHeaderSignatureError do
        Urlbox::WebhookValidator.call(header_signature, payload, webhook_secret)
      end

      assert_equal "Invalid signature", e.message
    end

    def test_call_invalid_hash_regex_catch
      header_signature = "t=#{timestamp_one_minute_ago},sha256=invalid_hash_regex"

      e = assert_raises Urlbox::InvalidHeaderSignatureError do
        Urlbox::WebhookValidator.call(header_signature, payload, webhook_secret)
      end

      assert_equal "Invalid signature", e.message
    end

    def test_call_invalid_timestamp
      header_signature = "t={invalid_timestamp},sha256=930ee08957512f247e289703ac951fc60da1e2d12919bfd518d90513b0687ee0"

      e = assert_raises Urlbox::InvalidHeaderSignatureError do
        Urlbox::WebhookValidator.call(header_signature, payload, webhook_secret)
      end

      assert_equal "Invalid timestamp", e.message
    end

    def test_call_invalid_timestamp_timing_attack
      timestamp_ten_minute_ago = (Time.now - 600).to_i
      header_signature = "t=#{timestamp_ten_minute_ago},sha256=930ee08957512f247e289703ac951fc60da1e2d12919bfd518d90513b0687ee0"

      e = assert_raises Urlbox::InvalidHeaderSignatureError do
        Urlbox::WebhookValidator.call(header_signature, payload, webhook_secret)
      end

      assert_equal "Invalid timestamp", e.message
    end
  end
end
