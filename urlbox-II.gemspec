lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'urlbox'
  spec.version       = '0.1.0'
  spec.authors       = ['Alan Donohoe']
  spec.email         = ['alan@urlbox.io']

  spec.summary       = 'Ruby wrapper for the Urlbox API'
  spec.homepage      = 'https://www.urlbox.io'
  spec.license       = 'MIT'

  # If you need to check in files that aren't .rb files, add them here
  spec.files         = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.md']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'openssl', '~> 2.2'

  spec.add_development_dependency 'bundler', '~> 2.2'
end
