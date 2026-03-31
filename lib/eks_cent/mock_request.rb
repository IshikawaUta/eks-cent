require 'stringio'

module EksCent
  class MockRequest
    def initialize(app)
      @app = app
    end

    def get(uri, opts = {})
      request('GET', uri, opts)
    end

    def post(uri, opts = {})
      request('POST', uri, opts)
    end

    def request(method, uri, opts = {})
      path, query = uri.split('?')
      env = {
        'REQUEST_METHOD' => method,
        'PATH_INFO'      => path,
        'QUERY_STRING'   => query || '',
        'HTTP_USER_AGENT' => opts[:user_agent] || 'EksCent-MockRequest',
      }.merge(opts[:env] || {})
      
      env['eks.input']   ||= StringIO.new(opts[:body] || '')
      env['rack.input']  ||= env['eks.input']
      env['eks.version'] ||= [1, 3]
      env['rack.version'] ||= env['eks.version']
      
      status, headers, body = @app.call(env)
      require_relative 'mock_response' unless defined?(EksCent::MockResponse)
      MockResponse.new(status, headers, body)
    end
  end
end
