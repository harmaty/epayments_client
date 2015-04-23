Ruby wrapper for epayments JSON API

## Installation

```ruby

gem 'epayments_client', :git => "git://github.com/harmaty/epayments_client.git"

```

## Usage

```ruby

   client = Epa::Json::Client.new 'username', 'password'

   client.balance

   client.transfer_funds from: '000-111111',
                         to: '000-999999',
                         amount: 100,
                         currency: 'USD',
                         details: 'my payment',
                         secret_code: '123456'
```