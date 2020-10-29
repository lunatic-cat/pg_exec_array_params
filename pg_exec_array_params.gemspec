# frozen_string_literal: true

require_relative 'lib/pg_exec_array_params/version'

Gem::Specification.new do |spec|
  spec.name          = 'pg_exec_array_params'
  spec.version       = PgExecArrayParams::VERSION
  spec.authors       = ['Vlad Bokov']
  spec.email         = ['vlad@lunatic.cat']

  spec.summary       = 'PG::Connection#exec_params with arrays'
  spec.description   = 'Escape each array element inside PG::Connection#exec_params properly'
  spec.homepage      = 'https://github.com/lunatic-cat/pg_exec_array_params'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/lunatic-cat/pg_exec_array_params'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency('pg', ENV.fetch('PG', '~> 0'))
  spec.add_dependency('pg_query', '~> 1.2')

  spec.add_development_dependency('pry-byebug', '~> 3.9')
  spec.add_development_dependency('rake', '~> 12.0')
  spec.add_development_dependency('rspec', '~> 3.0')
  spec.add_development_dependency('rspec-github', '~> 2.3')
  spec.add_development_dependency('rubocop', '~> 1.0')
  spec.add_development_dependency('rubocop-rspec', '~> 2.0.0.pre')
  spec.add_development_dependency('simplecov', '~> 0.19')
end