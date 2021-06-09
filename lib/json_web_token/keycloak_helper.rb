require 'ostruct'
require 'http'

module KeycloakHelper
  def self.config= config
    @config = OpenStruct.new(config.to_h)
  end

  def self.config
    @config
  end

  def self.default_audience
    config.default_access_token_audience
  end

  def self.client_id
    config.client_id
  end

  def self.default_realm
    config.default_realm
  end

  def self.issuer
    "#{config.host_url}/realms/#{default_realm}"
  end

  def self.base_url
    "#{issuer}/protocol/openid-connect"
  end

  def self.public_key token
    token_header = JsonWebToken.header token
    cache_key = "Keycloak:PublicKeys:#{token_header['alg']}:#{token_header['kid']}"

    key = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      certificates_response = HTTP.headers(accept: 'application/json').get("#{base_url}/certs")
      supported_keys = certificates_response.parse(:json)['keys']

      new_pub_key = supported_keys.detect { |cert| cert['alg'] == token_header['alg'] && cert['kid'] == token_header['kid'] }
      raise "Keycloak service does not provide a public key for #{token_header['alg']}:#{token_header['kid']} as required" if new_pub_key.nil?
      new_pub_key.to_json
    end

    JSON.parse(key)
  end
end
