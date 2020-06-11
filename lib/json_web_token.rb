require "json_web_token/version"

module JsonWebToken
  class Error < StandardError; end

  def self.signature_algorithm
    'RS256'
  end

  def self.header token
    JWT.decode(token, nil, false).last
  end

  def self.payload token, sub: '', verify: true
    if verify
      decode(token, sub: sub).first
    else
      JWT.decode(token, nil, false).first
    end
  end

  private

  # When requesting a new access token, the integrity of the token must be validated
  # by verifying the signature of the token as per chapter 10 of the openid standard, see here:
  # https://openid.net/specs/openid-connect-core-1_0.html#rfc.section.10
  def self.decode token, sub: ''
    unverified_payload = payload token, verify: false
    options = case unverified_payload['typ']
              when 'ID'
                {
                    iss: KeyCloakHelper.default_realm_issuer,
                    verify_iss: true,
                    aud: KeyCloakHelper.client_id,
                    verify_aud: true
                }
              when 'Bearer'
                {
                    iss: KeyCloakHelper.default_realm_issuer,
                    verify_iss: true,
                    sub: sub,
                    verify_sub: true,
                    aud: KeyCloakHelper.default_audience,
                    verify_aud: true,
                    verify_iat: true,
                    verify_jti: true # only testing for if jti is present, see: https://github.com/jwt/ruby-jwt#jwt-id-claim
                }
              else
                raise "JsonWebToken: Unsupported token type: #{unverified_payload['typ']}"
              end

    options.merge!({ algorithm: signature_algorithm })

    jwk = JSON::JWK.new public_key(token)

    JWT.decode token, jwk.to_key, true, options

  end

  def self.public_key token
    cached_public_key(header(token)) || new_public_key(header(token))
  end

  def self.redis_public_key_key token_header
    "KeyCloak:PublicKeys:#{token_header['alg']}:#{token_header['kid']}"
  end

  def self.update_public_key_cache token_header, new_pub_key
    redis_key = redis_public_key_key token_header
    RedisPool.with do |redis|
      redis.setex(redis_key, 24.hours.seconds.to_i, new_pub_key.to_json)
    end
    Rails.logger.info("JsonWebToken Redis: STORED #{redis_key}")
  end

  def self.cached_public_key token_header
    res = RedisPool.with do |redis|
      redis.get(redis_public_key_key(token_header))
    end
    Rails.logger.info("JsonWebToken Redis: GET #{redis_public_key_key(token_header)}")
    JSON.parse(res)
  end

  def self.new_public_key token_header
    Rails.logger.info("JsonWebToken: requesting new public key for #{token_header['alg']}:#{token_header['kid']}")
    new_pub_key = KeyCloakHelper.certificates.detect { |cert| cert['alg'] == token_header['alg'] && cert['kid'] == token_header['kid'] }
    raise "Keycloak service does not provide a public key for #{token_header['alg']}:#{token_header['kid']} as required" if new_pub_key.nil?
    update_public_key_cache token_header, new_pub_key
    new_pub_key
  end
end
