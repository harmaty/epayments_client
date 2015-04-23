module Epa
  module Json
    class PaymentException < StandardError
    end

    class AuthorizationError < StandardError
    end

  end
end
