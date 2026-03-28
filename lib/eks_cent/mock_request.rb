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
        'rack.input'     => StringIO.new(opts[:body] || '')
      }.merge(opts[:env] || {})
      
      @app.call(env)
    end
  end
end
