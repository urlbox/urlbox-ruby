lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'urlbox'
  spec.version       = '0.1.3'
  spec.authors       = ['Urlbox']
  spec.email         = ['support@urlbox.com']

  spec.summary       = 'Ruby wrapper for the Urlbox API'
  spec.description      = 'Urlbox is the easiest, quickest, screenshot API.  ' \
                       "See https://urlbox.com for details."
  spec.homepage      = 'https://urlbox.com'
  spec.license       = 'MIT'

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/urlbox/urlbox-ruby/issues",
    "documentation_uri" => "https://github.com/urlbox/urlbox-ruby",
    "github_repo" => "https://github.com/urlbox/urlbox-ruby",
    "homepage_uri" => "https://github.com/urlbox/urlbox-ruby",
    "source_code_uri" => "https://github.com/urlbox/urlbox-ruby",
  }

  # If you need to check in files that aren't .rb files, add them here
  spec.files         = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.md']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_runtime_dependency 'http', ['~> 5.0']
  spec.add_runtime_dependency 'openssl', ['~> 2.2']
end
