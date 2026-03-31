require 'test/unit'
require_relative '../lib/eks-cent'

class URLMapTest < Test::Unit::TestCase
  def test_url_mapping
    app = EksCent::Builder.new do
      map '/hello' do
        run lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ["Hello from /hello"]] }
      end
      
      map '/api' do
        run lambda { |env| [200, { 'Content-Type' => 'application/json' }, ['{"status":"ok"}']] }
      end
      
      run lambda { |env| [200, { 'Content-Type' => 'text/html' }, ["Root App"]] }
    end.to_app
    
    mock = EksCent::MockRequest.new(app)
    
    # Test Root
    res = mock.get('/')
    assert_equal 200, res.status
    assert_equal "Root App", res.body_content
    
    # Test /hello
    res = mock.get('/hello')
    assert_equal 200, res.status
    assert_equal "Hello from /hello", res.body_content
    
    # Test /api
    res = mock.get('/api')
    assert_equal 200, res.status
    assert_equal '{"status":"ok"}', res.body_content
    
    # Test 404 (on a non-mapped path if root didn't handle it, but here root handles everything)
    # Actually URLMap only returns 404 if no mapping matches AND no root app is provided.
  end
  
  def test_nested_mapping
    app = EksCent::Builder.new do
      map '/admin' do
        map '/dashboard' do
          run lambda { |env| [200, {}, ["Admin Dashboard"]] }
        end
        run lambda { |env| [200, {}, ["Admin Login"]] }
      end
    end.to_app
    
    mock = EksCent::MockRequest.new(app)
    
    assert_equal "Admin Dashboard", mock.get('/admin/dashboard').body_content
    assert_equal "Admin Login", mock.get('/admin').body_content
  end
end
