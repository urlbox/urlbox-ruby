module Urlbox
  class Error < StandardError
    def self.missing_api_secret_error_message
      <<-ERROR_MESSAGE
        Missing api_secret when initialising client or ENV['URLBOX_API_SECRET'] not set.
        Required for authorised post request.
      ERROR_MESSAGE
    end
  end

  class InvalidHeaderSignatureError < StandardError; end
end
