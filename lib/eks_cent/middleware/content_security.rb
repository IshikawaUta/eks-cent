module EksCent
  module Middleware
    class ContentSecurity
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        
        # Security headers
        headers['X-Frame-Options'] ||= 'SAMEORIGIN'
        headers['X-XSS-Protection'] ||= '1; mode=block'
        headers['X-Content-Type-Options'] ||= 'nosniff'
        headers['Referrer-Policy'] ||= 'strict-origin-when-cross-origin'
        
        [status, headers, body]
      end
    end
  end
end
