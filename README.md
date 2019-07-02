## Integration API

Easy communication between Jewlr servers using `HTTParty` and `JWT` using short living JWT tokens.

### Requirements
- HTTParty
- JWT
- Rails 5.0.0 or higher

## Setup

Run `rails g integration_api:install`
This command will generate IntegrationApi initializer that will look as such:

```ruby
IntegrationApi.configure do |config|
  # Secret key to decode tokens
  config.secret = 'your-secret-key'

  # Name of the server
  config.origin = 'server-name'

  # Allowed origin to respond
  config.allowed_origins = []
end

```

Add your configuration and your good to go.

**Note: in order for servers to communicate both need to have same `secret` key and have each others server names in `allowed_origins` array

## Usage

**Sample controller helper functions**
```ruby
class IntegrationController < ActionController::Base

  # Check integration token before processing request
  before_action :check_integration_token

  protected

  #
  # Validate token and allow/reject to proceed with request
  #
  def check_integration_token
    begin
      is_valid = IntegrationApi.validate(current_jwt)
      head :unauthorized unless is_valid
    rescue => ex
      head :unauthorized
    end
  end

  #
  # Get payload from JWT token
  #
  # @return [Hash/nil]
  #
  def show_payload
    begin
      payload = IntegrationApi.decode(current_jwt)
    rescue => ex
      return nil
    end
    payload
  end

  #
  # Get token from Authorization header
  #
  # @return [String]
  #
  def current_jwt
    authorization_header = request.headers['Authorization']
    raise 'Missing token' if authorization_header.blank?

    token = request.headers['Authorization'].split(' ')
    return token[1] if token.length > 1

    raise 'Invalid token'
  end
end

```


**Performing requests**

```ruby

  def get_users
    IntegrationApi.get('server/api/v1/users')
  end

  def create_user(payload)
    IntegrationApi.post('server/api/v1/users', payload)
  end

  def update_user(id, payload)
    IntegrationApi.put("server/api/v1/users/#{id}", payload)
  end

  def delete_user(id)
    IntegrationApi.delete("server/api/v1/users/#{id}")
  end

```

## [SafyreLabs :gem: ](https://www.safyrelabs.com/)