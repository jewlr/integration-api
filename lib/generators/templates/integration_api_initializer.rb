
IntegrationApi.configure do |config|
  # Secret key to decode tokens
  config.secret = 'your-secret-key'

  # Name of the server
  config.origin = 'server-name'

  # Allowed origin to respond
  config.allowed_origins = []

end