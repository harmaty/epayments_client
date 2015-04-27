require 'savon'
require 'active_support/all'

module Epa
  module Soap
    class Client

      attr_accessor :client_id, :secret_key, :config, :client

      DEFAULTS = {
          namespace_identifier: :tem,
          env_namespace: :soapenv,
          ssl_verify_mode: :none,
          wsdl: 'https://www.epayments.com/api_v1.3/APIService.svc?wsdl',
          log: false,
          adapter: :net_http
      }

      def initialize(client_id, secret_key, options = {})
        @client_id = client_id
        @secret_key = secret_key
        @config = DEFAULTS.merge options
      end

      def client
        @client = Savon.client wsdl: config[:wsdl],
                               namespace_identifier: config[:namespace_identifier],
                               env_namespace: config[:env_namespace],
                               ssl_verify_mode: config[:ssl_verify_mode],
                               log: config[:log],
                               adapter: config[:adapter]
      end

      # available operations for Epayments API
      def operations
        client.operations
      end

      def get_balances
        payload = {
            external_partner_id: client_id
        }

        call_soap_api __method__, payload, [:balances, :e_wallet_balance]
      end

      def get_balance(currency, wallet)
        payload = {
            external_partner_id: client_id,
            currency: currency,
            e_wallet: wallet
        }

        call_soap_api __method__, payload, :balance
      end

      def balance(currency = 'USD', e_wallet = nil)
        wallet = if e_wallet
          get_balances.detect{|b| b[:currency] == currency && b[:e_wallet_number] == e_wallet}
        else
          get_balances.detect{|b| b[:currency] == currency}
        end
        wallet[:balance].to_f if wallet
      end

      def internal_payment(options)
        payload = {
          external_partner_id: client_id,
          from_wallet_id: options[:from_wallet_id],
          to_wallet_id: options[:to_wallet_id],
          amount: options[:amount],
          currency: options[:currency],
          payment_id: options[:payment_id],
          details: options[:details]
        }

        call_soap_api __method__, payload, :transaction_id
      end

      def transfer_funds(options)
        internal_payment from_wallet_id: options[:from],
                         to_wallet_id: options[:to],
                         amount: options[:amount].to_f,
                         currency: options[:currency] || 'USD',
                         payment_id: options[:payment_id] || rand(2**32),
                         details: options[:details]
      end

      def get_incoming_transactions options
        payload = {
            external_partner_id: client_id,
            date_from: options[:date_from],
            date_to: options[:date_to],
            currency: options[:currency] || 'USD'
        }

        call_soap_api __method__, payload, [:transactions, :incoming_transaction]
      end

      def get_transaction(options)
        payload = {
            external_partner_id: client_id,
            e_wallet: options[:e_wallet],
            transaction_id: options[:transaction_id]
        }
        call_soap_api __method__, payload, :transaction
      end

      def call_soap_api operation, params, return_key = nil
        response = client.call operation, :message => prepare_body(params)
        result = response.body[:"#{operation}_response"][:"#{operation}_result"]
        if result[:response_code] == 'Ok'
          return result if return_key.nil?
          if return_key.is_a? Array
            return_key.each { |value| result = result.[](value) }
            result
          else
            result[return_key]
          end
        else
          raise ApiError, result[:response_code]
        end
      end

      private

      # generates signature
      def sign params
        signature = params.values.map { |v| format_before_sign(v) }.join('') + secret_key
        Digest::MD5.hexdigest(signature).upcase
      end

      # formats values to meet signature formatting requirements
      def format_before_sign value
        case value
          when Time
            value.strftime("%Y.%m.%d")
          when Float
            '%.2f' % value
          else
            value.to_s
        end
      end

      # generates body of SOAP request
      def prepare_body params
        body_params = ActiveSupport::OrderedHash.new
        params.each do |k, v|
          value = if v.respond_to? :strftime
                    v.strftime("%Y-%m-%dT%T")
                  else
                    v.to_s
                  end
          body_params[config[:namespace_identifier].to_s + ':' + k.to_s.camelize(:lower)] = value
        end
        body_params[config[:namespace_identifier].to_s + ":sign"] = sign(params)
        body_params
      end

    end
  end
end
