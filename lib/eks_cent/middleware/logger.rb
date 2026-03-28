module EksCent
  module Middleware
    class Logger
      def initialize(app, output = EksCent.logger)
        @app = app
        @output = output
      end

      def call(env)
        start_time = Time.now
        status, headers, body = @app.call(env)
        duration = Time.now - start_time
        
        @output.puts "[EksCent] #{Time.now} | #{env['REQUEST_METHOD']} #{env['PATH_INFO']} | Status: #{status} | Duration: #{'%.4f' % duration}s"
        
        [status, headers, body]
      end
    end
  end
end
