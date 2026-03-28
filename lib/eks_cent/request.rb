require 'uri'
require 'cgi'
require 'json'

module EksCent
  class Request
    attr_reader :env

    def initialize(env)
      @env = env
    end

    def request_method
      @env['REQUEST_METHOD']
    end

    def path
      @env['PATH_INFO'] || '/'
    end

    def query_string
      @env['QUERY_STRING'] || ''
    end

    def params
      @params ||= parse_params
    end

    def get?
      request_method == 'GET'
    end

    def post?
      request_method == 'POST'
    end

    def user_agent
      @env['HTTP_USER_AGENT']
    end

    def cookies
      @cookies ||= parse_cookies
    end

    def session
      @env['eks_cent.session'] ||= {}
    end

    private

    def parse_cookies
      cookie_header = @env['HTTP_COOKIE']
      return {} unless cookie_header
      
      CGI::Cookie.parse(cookie_header).transform_values(&:first)
    end

    def parse_params
      params = {}
      
      # Parse query string
      params.merge!(CGI.parse(query_string)) if query_string != ''

      # Parse router params if any
      if @env['eks_cent.router_params']
        params.merge!(@env['eks_cent.router_params'])
      end

      # Parse body based on content type
      if @env['rack.input']
        body = @env['rack.input'].read
        @env['rack.input'].rewind if @env['rack.input'].respond_to?(:rewind)
        
        if body && !body.empty?
          if @env['CONTENT_TYPE'] == 'application/json'
            begin
              params.merge!(JSON.parse(body))
            rescue JSON::ParserError
              # Silently ignore invalid JSON or we could log it
            end
          else
            # Default to form-urlencoded if it's a POST/PUT/PATCH
            params.merge!(CGI.parse(body)) if post? || @env['REQUEST_METHOD'] == 'PUT' || @env['REQUEST_METHOD'] == 'PATCH'
          end
        end
      end

      # Flatten single values
      params.transform_values { |v| v.is_a?(Array) && v.size == 1 ? v.first : v }
    end
  end
end
