Ruby wrapper for epayments JSON and SOAP API

## Installation

```ruby

gem 'epayments_client'

```

## Usage

```ruby

   # Using JSON API
   client = Epa::Client.new 'username', 'password', :json, log: true

   # Using SOAP API
   client = Epa::Client.new 'client_id', 'password', :soap, log: true

   client.balance

   client.transfer_funds from: '000-111111',
                         to: '000-999999',
                         amount: 100,
                         currency: 'USD',
                         details: 'my payment',
                         secret_code: '123456'

   client.transaction_history from: 1.hour.ago, to: 1.hour.from_now

```