module Epa
  module Json
    class ApiError < StandardError
    end

    class PaymentError < ApiError
    end

    class AuthorizationError < ApiError
    end

  end
end
