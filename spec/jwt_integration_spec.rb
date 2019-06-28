# frozen_string_literal: true

require 'spec_helper'
require 'integration_api'
require 'jwt'

RSpec.describe IntegrationApi, type: :class do
  context "IntegrationApi test suite" do
    before do
      IntegrationApi.configure do |config|
        config.secret = 'secret'
        config.origin = 'origin'
        config.alg = 'HS256'
        config.allowed_origins = %w(origin origin1 origin2)
      end
    end

    it 'should generate a token' do
      token = IntegrationApi.generate('System User')
      expect(token).to be_a(String)
    end

    it 'should decode token' do
      token = IntegrationApi.generate('System User', {foo: 'bar', bar: 'foo'})
      decoded_payload = IntegrationApi.decode(token)
      expect(decoded_payload['iss']).to eq('System User')
      expect(decoded_payload['data']['foo']).to eq('bar')
      expect(decoded_payload['data']['bar']).to eq('foo')
    end

    it 'should say that token is valid' do
      token = IntegrationApi.generate('System User', {foo: 'bar', bar: 'foo'})
      is_valid = IntegrationApi.validate(token)
      expect(is_valid).to be_truthy
    end

    it 'should say that token is invalid because expired' do
      token = IntegrationApi.generate('System User', {foo: 'bar', bar: 'foo'}, Time.now() - 4 * 3600)
      is_valid = IntegrationApi.validate(token)
      expect(is_valid).to be_falsey
    end

    it 'should say that token is invalid because different signature' do
      payload = {
        origin: 'origin',
        iss: 'System',
        exp: Time.now.to_i + 4 * 3600,
        iat: Time.now.to_i,
        data: nil
      }
      token = JWT.encode payload, 'different_secret', 'HS256'
      is_valid = IntegrationApi.validate(token)
      expect(is_valid).to be_falsey
    end

    it 'should say that token is invalid because empty token' do
      is_valid = IntegrationApi.validate('')
      expect(is_valid).to be_falsey
    end

    it 'should say that token is invalid because nil token' do
      is_valid = IntegrationApi.validate(nil)
      expect(is_valid).to be_falsey
    end

    it 'should add authentication header to headers object' do
      headers = {
          'Content-Type': 'application/json'
      }
      headers = IntegrationApi.add_auth_header(headers, 'System User Kim')
      expect(headers['Authorization']).to be_a(String)
      expect(headers['Authorization'].split(' ').size).to eq(2)
      token = headers['Authorization'].split(' ').last
      expect(IntegrationApi.validate(token)).to be_truthy
    end

    it 'should send a GET request with authorization headers' do
      url = 'https://www.myorigin.com/'
      stub_request(:get, url).to_return(body: {data: 'GET request'}.to_json)
      response = IntegrationApi.get(url)
      expect(JSON.parse(response.body)['data']).to eq('GET request')
    end

    it 'should send a POST request with authorization headers' do
      url = 'https://www.myorigin.com/'
      stub_request(:post, url).to_return(body: { data: 'POST request' }.to_json)
      response = IntegrationApi.post(url, { foo: 'bar' })
      expect(JSON.parse(response.body)['data']).to eq('POST request')
    end
  end
end
