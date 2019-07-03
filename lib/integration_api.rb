require 'active_support/core_ext/hash/indifferent_access'
require 'httparty'
#
# IntegrationApi module
# Allows server to server communication using
# JWT tokens with short TTL
#
module IntegrationApi
  # require 'jwt'
  # require 'indifferent_access'
  # require 'httparty'

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  #
  # Configuration class
  #
  class Configuration
    attr_accessor :secret, :allowed_origins, :alg, :origin

    def initialize
      @secret = nil
      @oirign = nil
      @alg = 'HS256'
      @allowed_origins = []
    end
  end

  #
  #  Generate authentication token to make request to external API
  #   Default issuer Jewlrorders from Rails.secrets
  #   Expiration defaulted to 4 minutes from issuing to make request
  #   then token will be dropped
  #
  # @param [Strign] issuer Defaulted to System user, can be any name
  # @param [Hash] data additional data encoded into the token
  # @param [String] Custom Secret Key to econde payload
  # @param [Time] exp token ttl
  #
  # @return [String] JWT
  #
  def self.generate(issuer: 'System', data: nil,
                          exp: Time.now.to_i + 4 * 3600, custom_secret_key: nil)
    payload = {
      origin: configuration.origin,
      iss: issuer,
      exp: exp,
      iat: Time.now.to_i,
      data: data
    }

    return JWT.encode payload, configuration.secret, configuration.alg if custom_secret_key.nil?

    JWT.encode payload, custom_secret_key, configuration.alg
  end

  #
  # Decode payload
  #
  # @param [String] payload
  # @param [String] custom_secret_key
  #
  # @return [nil/Hash] Hash payload data or nil if failed to decode
  #
  def self.decode(token, custom_secret_key: nil)
    begin
      secret = custom_secret_key
      secret = configuration.secret if custom_secret_key.nil?

      payload = JWT.decode token, secret, true,
                           { algorithm: configuration.alg }
    rescue => exception
      return nil
    end
    HashWithIndifferentAccess.new(payload.first)
  end

  #
  # Validate token for exp and allowed origins
  #
  # @param [String] payload
  #
  # @return [Boolean] true/false result of validation
  #
  def self.validate(token, custom_secret_key: nil)
    is_valid = false
    begin
      payload = decode(token, custom_secret_key: custom_secret_key)
      return is_valid if payload.nil?

      if configuration.allowed_origins.include?(payload['origin'])
        is_valid = true
      end
      is_valid
    end
  end

  #
  # Add authentication header field to Headers object
  #
  # @param [Hash] headers
  # @param [String] custom_secret_key
  # @param [String] issuer
  # @param [Hash] data
  #
  # @return [Hash] headers
  #
  def self.add_auth_header(headers, issuer = 'System', data = nil, custom_secret_key = nil)
    token = generate(issuer:issuer, data:data, custom_secret_key:custom_secret_key)
    headers['Authorization'] = "Bearer #{token}"
    headers
  end

  #
  # Send "POST" HTTP request with Auth headers attached
  #
  # @param [String] url
  # @param [Hash] data
  # @param [String] sender
  # @param [Hash] token_data token payload
  #
  # @return [HTTParty response] response
  #
  def self.post(url, data, wrap_in_data: true, custom_secret_key: nil, sender: 'System',
                headers: { 'Content-Type' => 'application/json' },
                token_data: nil)
    response_data = data
    response_data = { data: data } if wrap_in_data
    HTTParty.post(URI(url),
                  body: response_data.to_json,
                  headers: add_auth_header(headers, sender, token_data, custom_secret_key))
  end

  #
  # Send "PUT" HTTP request with Auth headers attached
  #
  # @param [String] url
  # @param [Hash] data
  # @param [String] sender
  # @param [Hash] token_data token payload
  #
  # @return [HTTParty response] response
  #
  def self.put(url, data, wrap_in_data:true, custom_secret_key: nil, sender: 'System',
               headers: { 'Content-Type' => 'application/json' },
               token_data: nil)
    response_data = data
    response_data = { data: data } if wrap_in_data
    HTTParty.put(URI(url),
    body: response_data.to_json,
    headers: add_auth_header(headers, sender, token_data, custom_secret_key))
  end

  #
  # Send "GET" HTTP request with Auth headers attached
  #
  # @param [String] url
  # @param [String] sender
  # @param [Hash] token_data token payload
  #
  # @return [HTTParty response] response
  #
  def self.get(url, custom_secret_key: nil, sender: 'System',
               headers: { 'Content-Type' => 'application/json' },
               token_data: nil)
    HTTParty.get(URI(url), headers:
                 add_auth_header(headers, sender, token_data, custom_secret_key))
  end

  #
  # Send "DELETE" HTTP request with Auth headers attached
  #
  # @param [String] url
  # @param [String] sender
  # @param [Hash] headers
  #
  # @return [HTTParty response] response
  #
  def self.delete(url, custom_secret_key: nil, sender: 'System',
    headers: { 'Content-Type' => 'application/json' },
    token_data: nil)
    HTTParty.delete(URI(url),
      headers: add_auth_header(headers, sender, token_data, custom_secret_key))
  end
end