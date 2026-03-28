module EksCent
  module Middleware
    class ShowExceptions
      def initialize(app)
        @app = app
      end

      def call(env)
        begin
          @app.call(env)
        rescue => e
          if EksCent.production?
            render_production_error
          else
            render_exception(e)
          end
        end
      end

      private

      def render_production_error
        [500, { 'Content-Type' => 'text/html' }, ["<html><body><h1>500 Internal Server Error</h1><p>Maaf, terjadi kesalahan pada server kami. Sila hubungi tim support jika masalah berlanjut.</p></body></html>"]]
      end

      def render_exception(e)
        status = 500
        headers = { 'Content-Type' => 'text/html' }
        body = [<<-HTML]
        <!DOCTYPE html>
        <html>
        <head>
          <title>Eks-Cent: Gagal Diproses</title>
          <style>
            body { font-family: 'Inter', sans-serif; background: #fafafa; color: #d32f2f; padding: 20px; }
            .container { background: white; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); padding: 30px; border-left: 5px solid #d32f2f; }
            h1 { color: #d32f2f; }
            pre { background: #eee; padding: 15px; border-radius: 4px; overflow-x: auto; color: #333; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>#{e.class}: #{e.message}</h1>
            <p><strong>Stack Trace:</strong></p>
            <pre>#{e.backtrace.join("\n")}</pre>
          </div>
        </body>
        </html>
        HTML
        
        [status, headers, body]
      end
    end
  end
end
