# Eks-Cent: Lightweight Rack-like Communication Interface for Ruby.

require_relative 'eks_cent/version'
require_relative 'eks_cent/request'
require_relative 'eks_cent/response'
require_relative 'eks_cent/builder'
require_relative 'eks_cent/router'
require_relative 'eks_cent/mock_request'
require_relative 'eks_cent/middleware/logger'
require_relative 'eks_cent/middleware/session'
require_relative 'eks_cent/middleware/content_security'
require_relative 'eks_cent/middleware/show_exceptions'
require_relative 'eks_cent/middleware/static'

module EksCent
  
  class << self
    attr_accessor :logger, :secret_key_base
  end
  self.logger = $stdout
  # Default secret key (sebaiknya diatur via ENV di produksi)
  self.secret_key_base = ENV['EKS_CENT_SECRET_KEY_BASE'] || '1e8a93e80c85b1a6c4b69d9c2e8b2a1a8e1b1d8c1c2e1f2g1h1i1j1k1l1m1n1o'

  def self.env
    ENV['RACK_ENV'] || ENV['EKS_CENT_ENV'] || 'development'
  end

  def self.production?
    env == 'production'
  end

  # Helper to create a new app directly
  def self.build(&block)
    Builder.new(&block).to_app
  end

  # Helper to load from file
  def self.load(file)
    Builder.parse_file(file)
  end
end
