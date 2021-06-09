# Wrapper around jwt access token
class JwtAccessToken
  attr_reader :jwt,:use_until

  def initialize jwt:,expires_in: nil
    @jwt = jwt
    if expires_in
      @use_until = Time.now + (expires_in / 2)
    end
  end

  def jwt_data subject: nil
    @jwt_data ||= begin
      if subject.nil? #don't verify sub when handling request with direct access token
        unverified_data = JWT.decode(jwt,nil,false)
        subject = unverified_data.first['sub']
      end
      JsonWebToken.payload jwt, sub: subject, public_key: KeycloakHelper.public_key(jwt)
    end
  end

  def expired?
    Time.now > (use_until || token_exp)
  end

  def token_exp
    @token_exp ||= Time.at(jwt_data['exp'])
  end

  def valid?
    (jwt_data rescue false) && !expired?
  end

  def user
    jwt_data["email"] || jwt_data["preferred_username"]
  end

  def roles
    jwt_data['realm_access']['roles']
  end

  def access_token
    self
  end

  def to_s
    jwt.to_s
  end

  def bearer_token
    jwt.to_s
  end
end
