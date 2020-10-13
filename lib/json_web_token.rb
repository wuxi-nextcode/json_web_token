require "json_web_token/version"
require "json_web_token/configuration"
require "jwt"
require 'json/jwk'

module JsonWebToken

  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.header token
    JWT.decode(token, nil, false).last
  end

  def self.payload token, sub: '', verify: true, public_key: nil
    if verify
      decode(token, sub: sub, public_key: public_key).first
    else
      JWT.decode(token, nil, false).first
    end
  end

  private

  # When requesting a new access token, the integrity of the token must be validated
  # by verifying the signature of the token as per chapter 10 of the openid standard, see here:
  # https://openid.net/specs/openid-connect-core-1_0.html#rfc.section.10
  def self.decode token, sub: '', public_key: nil
    unverified_payload = payload token, verify: false
    options = case unverified_payload['typ']
              when 'ID'
                {
                    iss: configuration.default_realm_issuer,
                    verify_iss: true,
                    aud: configuration.client_id,
                    verify_aud: true
                }
              when 'Bearer'
                {
                    iss: configuration.default_realm_issuer,
                    verify_iss: true,
                    sub: sub,
                    verify_sub: true,
                    aud: configuration.default_audience,
                    verify_aud: true,
                    verify_iat: true,
                    verify_jti: true # only testing for if jti is present, see: https://github.com/jwt/ruby-jwt#jwt-id-claim
                }
              else
                raise "JsonWebToken: Unsupported token type: #{unverified_payload['typ']}"
              end

    options.merge!({algorithm: configuration.signature_algorithm})

    jwk = JSON::JWK.new public_key

    JWT.decode token, jwk.to_key, true, options

  end
end
