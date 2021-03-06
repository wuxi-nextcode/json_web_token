module JsonWebToken
  class Configuration
    attr_accessor :signature_algorithm, :default_realm_issuer, :client_id, :default_audience

    def initialize
      @signature_algorithm = nil
      @default_realm_issuer = nil
      @client_id = nil
      @default_audience = nil
    end
  end
end
