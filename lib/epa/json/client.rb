require 'net/https'
require 'logger'

module Epa
  module Json
    class Client

      DEFAULTS = {
          api_secret: 'mYn6hrkg0ILqrtIp8KSD',
          api_name: 'epayments'
      }

      API_URL = 'https://api.epayments.com'

      attr_accessor :token, :config, :logger

      def initialize(username, password, options = {})
        @username = username
        @password = password
        @config = DEFAULTS.merge options
        @logger = Logger.new STDOUT
      end

      def get_token
        data_hash = {
            grant_type: 'password',
            username: @username,
            password: @password
        }
        secret = Base64.encode64("#{config[:api_name]}:#{config[:api_secret]}")

        response = call_json_api '/token', 'POST', data_hash.to_query, 'Authorization' => "Basic #{secret}"
        raise AuthorizationError, response["error_description"] unless response["access_token"]
        response["access_token"]
      end

      def balance(currency = 'USD', ep_id = nil)
        response = user_info
        wallet = if ep_id
                   response["ewallets"].detect { |w| w["ePid"] == ep_id }
                 else
                   response["ewallets"].first
                 end
        raise ApiError, 'wallet not found' unless wallet
        wallet["balances"].detect { |b| b["currency"] == currency.downcase }["currentBalance"]
      end

      def transfer_funds(options = {})
        payload = {
            confirmation: nil,
            mode: "ValidateAndExecute",
            sourcePurse: options[:from],
            transfers: [
                {
                    amount: options[:amount],
                    currency: options[:currency] || 'USD',
                    details: options[:details],
                    paymentReceiver: options[:to]
                }
            ]
        }

        response = internal_payment payload
        raise PaymentError, response["errorMsgs"].join(', ') unless response["confirmationMessage"]

        payload[:confirmation] = {
            code: guess_code(options[:secret_code], response["confirmationMessage"]),
            sessionId: response["confirmationSessionId"]
        }

        result_response = internal_payment payload
        result_response["transfers"].first["transactionId"]
      end

      def user_info
        call_json_api '/v1/user', 'GET', "", headers
      end

      def internal_payment(payload)
        call_json_api '/v1/InternalPayment/', 'PUT', payload.to_json, headers
      end

      def transaction_history(options)
        payload = {
          from: options[:from].to_i || 1.day.ago.to_i,
          till: options[:to].to_i || Time.now.to_i,
          take: options[:take] || 20,
          skip: options[:skip] || 0
        }

        response = call_json_api '/v1/transactions', 'POST', payload.to_json, headers
        response["transactions"]
      end

      private

      def headers
        @token ||= get_token
        {
            'Authorization' => "Bearer #{@token}",
            'Accept' => 'application/json',
            'Content-Type' => 'application/json'
        }
      end

      def call_json_api(path, method = 'get', payload = "", headers = {})
        uri = URI(API_URL)
        uri.path = path
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = "Net::HTTP::#{method.downcase.camelize}".constantize.new(uri.request_uri, headers)
        request.body = payload
        logger.info "Request path: #{path}, payload: #{payload}"

        # Send the request
        response = http.request(request)
        json_response = JSON.parse(response.body)

        logger "Response: #{json_response.inspect}"
        json_response
      end

      def guess_code(code, message)
        numbers = message.scan(/\d\,\d\,\d/).first
        numbers.split(/\,/).map { |i| code[i.to_i - 1] }.join
      end

    end
  end
end
