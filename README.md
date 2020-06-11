# JsonWebToken

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/json_web_token`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_web_token', git: 'https://gitlab.com/wuxi-nextcode/cla/json_web_token.git'
```

To be able to install this gem you will have to generate a username/password "deploy token". This can be done under Settings->Repository->Deploy Tokens. Be sure to only allow read access to the repository.

Then add authentication to bundler config (locally or in your Dockerfile), using the username/password from the "deploy token":

    $ bundle config https://gitlab.com/wuxi-nextcode/cla/json_web_token.git "${USERNAME}:${PASSWORD}"

And then you can execute:

    $ bundle

## Usage

To configure create a initializer file, e.g. config/initializers/json_web_token_config.rb. 

```ruby
JsonWebToken.configure do |config|
  config.signature_algorithm = 'RS256'
  config.default_realm_issuer = KeyCloakHelper.default_realm_issuer
  config.client_id = KeyCloakHelper.client_id
  config.default_audience = KeyCloakHelper.default_audience
end
```    
```ruby
```

You can decode and view token headers with:

```ruby
    JsonWebToken.header(token)
```
Where
* `token`: the jwt token to decode

And decode and view verified (or unverified) token payloads with:

```ruby
    JsonWebToken.payload(token, sub: sub, verify: true, public_key: public_key)
```

Where
* `token`: the jwt token to decode
* `sub`: the subject to compare the token payload to
* `public_key`: the public key used to encode token
* `verify`: can be set to false to view token payload unverified (defaults to true when omitted)

It's up to the application using this gem to handle fetching the public key from the authentication server and passing into the payload function. It's recommended to use both the alg and kid values from the token and fetch a certificate from the authentication server (or used a cached one) based on those values. An example of a code that deos this is
```ruby
def self.public_key token
  cached_public_key(JsonWebToken.header(token)) || new_public_key(JsonWebToken.header(token))
end

private

def self.redis_public_key_key token_header
  "KeyCloak:PublicKeys:#{token_header['alg']}:#{token_header['kid']}"
end

def self.update_public_key_cache token_header, new_pub_key
    redis_key = redis_public_key_key token_header
    RedisPool.with do |redis|
      redis.setex(redis_key, 24.hours.seconds.to_i, new_pub_key.to_json)
    end
    Rails.logger.info("KeyCloakHelper Redis: STORED #{redis_key}")
end

def self.cached_public_key token_header
    res = RedisPool.with do |redis|
      redis.get(redis_public_key_key(token_header))
    end
    Rails.logger.info("KeyCloakHelper Redis: GET #{redis_public_key_key(token_header)}")
    JSON.parse(res)
end

def self.new_public_key token_header
    Rails.logger.info("KeyCloakHelper: requesting new public key for #{token_header['alg']}:#{token_header['kid']}")
    new_pub_key = certificates_from_keycloak.detect { |cert| cert['alg'] == token_header['alg'] && cert['kid'] == token_header['kid'] }
    raise "Keycloak service does not provide a public key for #{token_header['alg']}:#{token_header['kid']} as required" if new_pub_key.nil?
    update_public_key_cache token_header, new_pub_key
    new_pub_key
end 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://gitlab.com/wuxi-nextcode/cla/json_web_token. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonWebToken project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/json_web_token/blob/master/CODE_OF_CONDUCT.md).
