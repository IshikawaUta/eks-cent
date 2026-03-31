require 'test/unit'
require_relative '../lib/eks-cent'

class RouterTest < Test::Unit::TestCase
  def setup
    @router = EksCent::Router.new do
      get '/' do |req, res|
        res.write "Home"
      end

      get '/hello/:name' do |req, res|
        res.write "Hello #{req.params['name']}"
      end

      post '/submit' do |req, res|
        res.status = 201
        res.write "Submitted #{req.params['data']}"
      end
    end
  end

  def test_root_path
    env = { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/' }
    status, _headers, body = @router.call(env)
    
    assert_equal 200, status
    assert_equal ["Home"], body
  end

  def test_dynamic_param
    env = { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/hello/Antigravity' }
    status, _headers, body = @router.call(env)
    
    assert_equal 200, status
    assert_equal ["Hello Antigravity"], body
  end

  def test_post_method
    # Mock eks.input for POST
    input = StringIO.new("data=penting")
    env = { 
      'REQUEST_METHOD' => 'POST', 
      'PATH_INFO' => '/submit',
      'eks.input' => input,
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    }
    status, _headers, body = @router.call(env)
    
    assert_equal 201, status
    assert_equal ["Submitted penting"], body
  end

  def test_not_found
    env = { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/unknown' }
    status, _headers, _body = @router.call(env)
    
    assert_equal 404, status
  end
end
