module EksCent
  module Middleware
    class Runtime
      def initialize(app, header_name = 'X-Runtime')
        @app = app
        @header_name = header_name
      end

      def call(env)
        start_time = Time.now
        status, headers, body = @app.call(env)
        duration = Time.now - start_time

        headers[@header_name] = format("%0.6f", duration)
        [status, headers, body]
      end
    end
  end
end
