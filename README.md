# JsonWebToken

Ruby gem for JWT verification

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_web_token', git: 'https://github.com/wuxi-nextcode/json_web_token.git'
```

To be able to install this gem you will have to generate a username/password "deploy token". This can be done under Settings->Repository->Deploy Tokens. Be sure to only allow read access to the repository.

Then add authentication to bundler config (locally or in your Dockerfile), using the username/password from the "deploy token":

    $ bundle config https://gitlab.com/wuxi-nextcode/cla/json_web_token.git "${USERNAME}:${PASSWORD}"
    
And then you can execute:

    $ bundle

## Usage

To configure create a initializer file, e.g. config/initializers/json_web_token_config.rb. 

```ruby
KeyCloakHelper.config = {
  host_url: ENV["KEYCLOAK_HOST"],
  default_realm: "my_realm",
  client_id: "my_client",
  default_access_token_audience: ['aud1','account'] 
}
JsonWebToken.configure do |config|
  config.signature_algorithm = 'RS256'
  config.default_realm_issuer = KeyCloakHelper.default_realm_issuer
  config.client_id = KeyCloakHelper.client_id
  config.default_audience = KeyCloakHelper.default_audience
end
```

You can decode and view token headers with:

```ruby
    JsonWebToken.header(token)
```
Where
* `token`: the jwt token to decode

And decode and view verified (or unverified) token payloads with:

```ruby
    JsonWebToken.payload(token, sub: sub, verify: true, public_key: KeycloakHelper.public_key(token))
```

Where
* `token`: the jwt token to decode
* `sub`: the subject to compare the token payload to
* `public_key`: the public key used to encode token
* `verify`: can be set to false to view token payload unverified (defaults to true when omitted)

### Access Token
The gem provides an AccessToken class that wraps the jwt and contains convenince methods when dealing with Access Tokens.

Usage example:
```ruby
 at = AccessToken.new(jwt: raw_jwt)
 raise 'Invalid Token' unless at.valid?
 puts "User: #{at.user}"
 if at.roles.include?("admin")
   puts "Admin user"
 end
 
 puts "Subject: #{at.jwt_data['sub']}"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`.

## Contributing

Bug reports and pull requests are welcome on Gitlab at https://gitlab.com/wuxi-nextcode/cla/json_web_token. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonWebToken project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/json_web_token/blob/master/CODE_OF_CONDUCT.md).
