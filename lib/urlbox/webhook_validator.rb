require 'urlbox/errors'

module Urlbox
  class WebhookValidator
    SIGNATURE_REGEX = /^sha256=[0-9a-zA-Z]{40,}$/.freeze
    TIMESTAMP_REGEX = /^t=[0-9]+$/.freeze
    WEBHOOK_AGE_MAX_MINUTES = 5

    class << self
      def call(header_signature, payload, webhook_secret)
        timestamp, signature = header_signature.split(',')

        check_timestamp(timestamp)
        check_signature(signature, timestamp, payload, webhook_secret)

        true
      end

      def check_signature(raw_signature, timestamp, payload, webhook_secret)
        raise Urlbox::InvalidHeaderSignatureError, 'Invalid signature' unless SIGNATURE_REGEX.match?(raw_signature)

        signature_webhook = raw_signature.split('=')[1]
        timestamp_parsed = timestamp.split('=')[1]
        signature_generated =
          OpenSSL::HMAC.hexdigest('sha256',
                                  webhook_secret.encode('UTF-8'),
                                  "#{timestamp_parsed}.#{JSON.dump(payload).encode('UTF-8')}")

        raise Urlbox::InvalidHeaderSignatureError, 'Invalid signature' unless signature_generated == signature_webhook
      end

      def check_timestamp(raw_timestamp)
        raise Urlbox::InvalidHeaderSignatureError, 'Invalid timestamp' unless TIMESTAMP_REGEX.match?(raw_timestamp)

        timestamp = (raw_timestamp.split('=')[1]).to_i

        check_webhook_creation_time(timestamp)
      end

      def check_webhook_creation_time(header_timestamp)
        current_timestamp = Time.now.to_i
        webhook_posted = current_timestamp - header_timestamp
        webhook_posted_minutes_ago = webhook_posted / 60

        if webhook_posted_minutes_ago > WEBHOOK_AGE_MAX_MINUTES
          raise Urlbox::InvalidHeaderSignatureError, 'Invalid timestamp'
        end
      end
    end

    private_class_method :check_signature, :check_timestamp, :check_webhook_creation_time
  end
end
