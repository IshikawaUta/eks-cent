# eks-cent.gemspec
require_relative 'lib/eks_cent/version'

Gem::Specification.new do |spec|
  spec.name          = "eks-cent"
  spec.version       = EksCent::VERSION
  spec.authors        = ["IshikawaUta"]
  spec.email          = ["komikers09@gmail.com"]

  spec.summary       = "Framework web Ruby ringan, aman, dan siap produksi berbasis Rack."
  spec.description   = "Eks-Cent adalah framework web minimalis yang menyediakan sistem routing canggih, manajemen session HMAC, dan proteksi keamanan bawaan menggunakan Eksa-Server sebagai engine utama."
  spec.homepage      = "https://github.com/IshikawaUta/eks-cent"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*'] + Dir['bin/*'] + ['README.md', 'LICENSE', 'config.eks']
  spec.bindir        = "bin"
  spec.executables   = ["ekscentup"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "eksa-server", "~> 1.1"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
end
