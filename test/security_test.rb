require 'test/unit'
require_relative '../lib/eks-cent'
require 'fileutils'
require 'openssl'

class SecurityTest < Test::Unit::TestCase
  def setup
    @app = EksCent::Builder.new do
      use EksCent::Middleware::ContentSecurity
      use EksCent::Middleware::Session
      use EksCent::Middleware::ShowExceptions
      
      run EksCent::Router.new {
        get '/set' do |req, res|
          req.session['user_id'] = 123
          res.write "Session set"
        end

        get '/read' do |req, res|
          res.write "User: #{req.session['user_id']}"
        end

        get '/render' do |req, res|
          res.render 'test', name: req.params['name']
        end

        get '/error' do |req, res|
          raise "Boom!"
        end
      }
    end
    @mock = EksCent::MockRequest.new(@app)
    # Reset ENV for tests
    ENV.delete('RACK_ENV')
  end

  def test_signed_session_integrity
    # 1. Set session
    _status, headers, _body = @mock.get('/set')
    cookie = headers['Set-Cookie']
    
    # 2. Tamper with cookie (change data but keep signature or vice versa)
    _, sig = cookie.split(';').first.split('=').last.split('--')
    tampered_data = Base64.strict_encode64('{"user_id":999}')
    tampered_cookie = "_eks_cent_session=#{tampered_data}--#{sig}"
    
    # 3. Read with tampered cookie
    _status, _headers, body = @mock.get('/read', env: { 'HTTP_COOKIE' => tampered_cookie })
    assert_equal ["User: "], body # Should be empty because signature mismatch
  end

  def test_html_escape_h_helper
    # Test with malicious script
    malicious = "<script>alert(1)</script>"
    _status, _headers, body = @mock.get('/render', env: { 'QUERY_STRING' => "name=#{CGI.escape(malicious)}" })
    
    assert body.first.include?("&lt;script&gt;alert(1)&lt;/script&gt;")
    assert !body.first.include?("<script>")
  end

  def test_security_headers
    _status, headers, _body = @mock.get('/set')
    assert_equal 'SAMEORIGIN', headers['X-Frame-Options']
    assert_equal '1; mode=block', headers['X-XSS-Protection']
    assert_equal 'nosniff', headers['X-Content-Type-Options']
  end

  def test_production_exception_hiding
    ENV['RACK_ENV'] = 'production'
    status, _headers, body = @mock.get('/error')
    
    assert_equal 500, status
    assert body.first.include?("500 Internal Server Error")
    assert !body.first.include?("Boom!") # No error message leak
    assert !body.first.include?("test/security_test.rb") # No stack trace leak
    ENV.delete('RACK_ENV')
  end
end
