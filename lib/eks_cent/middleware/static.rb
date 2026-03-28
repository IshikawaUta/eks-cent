require 'fileutils'

module EksCent
  module Middleware
    class Static
      MIME_TYPES = {
        '.html' => 'text/html',
        '.css'  => 'text/css',
        '.js'   => 'application/javascript',
        '.png'  => 'image/png',
        '.jpg'  => 'image/jpeg',
        '.gif'  => 'image/gif',
        '.ico'  => 'image/x-icon',
        '.txt'  => 'text/plain',
        '.xml'  => 'application/xml',
        '.svg'  => 'image/svg+xml'
      }

      def initialize(app, root: 'public')
        @app = app
        @root = root
      end

      def call(env)
        path = env['PATH_INFO']
        
        # Prevent path traversal attacks
        if path.include?('..')
          return [403, { 'Content-Type' => 'text/plain' }, ["Forbidden (Path Traversal)"]]
        end

        file_path = File.join(@root, path)

        if File.file?(file_path)
          serve_file(file_path)
        else
          @app.call(env)
        end
      end

      private

      def serve_file(path)
        ext = File.extname(path).downcase
        content_type = MIME_TYPES[ext] || 'application/octet-stream'
        
        headers = { 
          'Content-Type' => content_type,
          'Cache-Control' => 'public, max-age=86400' # Cache for 1 day
        }
        
        [200, headers, [File.read(path)]]
      end
    end
  end
end
