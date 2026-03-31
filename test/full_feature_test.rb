require 'test/unit'
require_relative '../lib/eks-cent'
require 'fileutils'

class FullFeatureTest < Test::Unit::TestCase
  def setup
    @app = EksCent::Builder.new do
      use EksCent::Middleware::Session
      
      run EksCent::Router.new {
        get '/' do |req, res|
          req.session['v'] ||= 0
          req.session['v'] += 1
          res.write "View count: #{req.session['v']}"
        end

        namespace '/api' do
          post '/json' do |req, res|
            res.headers['Content-Type'] = 'application/json'
            res.write({ status: 'ok', received: req.params['data'] }.to_json)
          end
        end

        get '/cookie' do |req, res|
          res.set_cookie('tema', 'gelap')
          res.write "Cookie set"
        end
      }
    end
    @mock = EksCent::MockRequest.new(@app)
  end

  def test_session_persistence
    # Request 1
    _status, headers, body = @mock.get('/')
    assert_equal ["View count: 1"], body
    session_cookie = headers['Set-Cookie']
    
    # Request 2 with the same cookie
    env = { 'HTTP_COOKIE' => session_cookie }
    _status, headers, body = @mock.get('/', env: env)
    assert_equal ["View count: 2"], body
  end

  def test_json_parsing
    input = JSON.dump({ data: 'mantap' })
    env = { 
      'CONTENT_TYPE' => 'application/json',
      'eks.input' => StringIO.new(input)
    }
    _status, _headers, body = @mock.post('/api/json', env: env)
    
    result = JSON.parse(body.first)
    assert_equal 'mantap', result['received']
  end

  def test_namespace_routing
    status, _headers, _body = @mock.post('/api/json', env: { 
      'CONTENT_TYPE' => 'application/json',
      'eks.input' => StringIO.new('{"data":1}') 
    })
    assert_equal 200, status
  end

  def test_cookie_setting
    _status, headers, _body = @mock.get('/cookie')
    assert headers['Set-Cookie'].include?('tema=gelap')
  end
end
