module EksCent
  class MockResponse
    attr_reader :status, :headers, :body

    def initialize(status, headers, body)
      @status = status.to_i
      @headers = headers
      @body = body
    end

    def body_content
      @body.is_a?(Array) ? @body.join : @body.to_s
    end

    def ok?
      @status == 200
    end

    def redirect?
      [301, 302, 303, 307, 308].include?(@status)
    end

    def client_error?
      @status >= 400 && @status < 500
    end

    def server_error?
      @status >= 500 && @status < 600
    end

    def not_found?
      @status == 404
    end

    def location
      @headers['Location']
    end

    def content_type
      @headers['Content-Type']
    end

    def to_ary
      [@status, @headers, @body]
    end
  end
end
