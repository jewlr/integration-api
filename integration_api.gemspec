Gem::Specification.new do |spec|
  spec.name        = 'integration_api'
  spec.version     = '1.1.1'
  spec.date        = '2019-06-28'
  spec.summary     = "Easy short secret key based JWT communication between servers"
  spec.description = "JWT communication gem"
  spec.authors     = ["Rem Kim"]
  spec.email       = 'rem@jewlr.com'
  spec.files       = ["lib/integration_api.rb"]
  spec.homepage    =
    'https://github.com/jewlr/integration-api.git'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 2.1'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-json'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'codacy-coverage'
  spec.add_development_dependency 'webmock'
  spec.add_dependency 'jwt'
  spec.add_dependency 'httparty'
  spec.add_dependency 'activesupport'
end
