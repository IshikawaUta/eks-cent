require 'test/unit'
require_relative '../lib/eks-cent'

class CascadeTest < Test::Unit::TestCase
  def test_cascade_fallback
    app1 = lambda { |env| [404, { 'X-Cascade' => 'pass' }, ["Not Found 1"]] }
    app2 = lambda { |env| [404, { 'X-Cascade' => 'pass' }, ["Not Found 2"]] }
    app3 = lambda { |env| [200, {}, ["Found in App 3"]] }
    
    cascade = EksCent::Cascade.new([app1, app2, app3])
    
    mock = EksCent::MockRequest.new(cascade)
    res = mock.get('/')
    
    assert_equal 200, res.status
    assert_equal "Found in App 3", res.body_content
  end
  
  def test_cascade_fails_completely
    app1 = lambda { |env| [status = 404, { 'X-Cascade' => 'pass' }, ["Not Found 1"]] }
    cascade = EksCent::Cascade.new([app1])
    
    mock = EksCent::MockRequest.new(cascade)
    res = mock.get('/')
    
    assert_equal 404, res.status
    assert_equal "Not Found 1", res.body_content
  end
end
