require 'active_support/core_ext/hash/indifferent_access'
require 'httparty'
#
# IntegrationApi module
# Dedicated to allow easy communications between API services without using access tokens
#
module IntegrationApi
  # require 'jwt'
  # require 'hashr'
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
      @secret = 'secret'
      @allowed_origins = []
      @alg = 'HS256'
      @oirign = 'origin'
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
  # @param [Time] exp token ttl
  #
  # @return [String] JWT
  #
  def self.generate(issuer = 'System', data = nil,
                          exp = Time.now.to_i + 4 * 3600)
    payload = {
      origin: configuration.origin,
      iss: issuer,
      exp: exp,
      iat: Time.now.to_i,
      data: data
    }
    JWT.encode payload, configuration.secret, configuration.alg
  end

  #
  # Decode payload
  #
  # @param [String] payload
  #
  # @return [nil/Hash] Hash payload data or nil if failed to decode
  #
  def self.decode(token)
    begin
      payload = JWT.decode token, configuration.secret, true,
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
  def self.validate(token)
    is_valid = false
    begin
      payload = decode(token)
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
  # @param [String] issuer
  # @param [Hash] data
  #
  # @return [Hash] headers
  #
  def self.add_auth_header(headers, issuer = 'System', data = nil)
    token = generate(issuer, data)
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
  def self.post(url, data, wrap_in_data=true, sender = 'System',
                headers = { 'Content-Type' => 'application/json' },
                token_data = nil)
    response_data = data
    response_data = { data: data } if wrap_in_data
    HTTParty.post(URI(url),
                  body: response_data.to_json,
                  headers: add_auth_header(headers, sender, token_data))
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
  def self.put(url, data, wrap_in_data=true, sender = 'System',
               headers = { 'Content-Type' => 'application/json' },
               token_data = nil)
    response_data = data
    response_data = { data: data } if wrap_in_data
    HTTParty.put(URI(url),
    body: response_data.to_json,
    headers: add_auth_header(headers, sender, token_data))
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
  def self.get(url, sender = 'System',
               headers = { 'Content-Type' => 'application/json' },
               token_data = nil)
    HTTParty.get(URI(url), headers:
                 add_auth_header(headers, sender, token_data))
  end
end