module IntegrationApi
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
      desc "Creates IntegrationApi initializer for your application"

      def copy_initializer
        template "integration_api_initializer.rb", "config/initializers/integration_api.rb"

        puts "IntegrationApi installed!"
      end
    end
  end
end