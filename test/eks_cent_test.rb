require_relative '../lib/eks-cent'
require 'test/unit'

class EksCentTest < Test::Unit::TestCase
  def test_basic_request_response
    app = lambda do |env|
      req = EksCent::Request.new(env)
      res = EksCent::Response.new
      res.write "Halo, #{req.params['name']}!" if req.params['name']
      res.finish
    end

    mock = EksCent::MockRequest.new(app)
    status, _headers, body = mock.get('/?name=Andi')
    
    assert_equal 200, status
    assert_equal ['Halo, Andi!'], body
  end

  def test_middleware_order
    # order = [] # Variabel dihilangkan karena tidak digunakan secara langsung
    
    m1 = Class.new do
      def initialize(app); @app = app; end
      def call(env); env['order'] << 1; @app.call(env); end
    end
    
    m2 = Class.new do
      def initialize(app); @app = app; end
      def call(env); env['order'] << 2; @app.call(env); end
    end

    app = EksCent::Builder.new do
      use m1
      use m2
      run lambda { |env| [200, {}, ["OK"]] }
    end.to_app

    env = { 'order' => [] }
    EksCent::MockRequest.new(app).get('/', env: env)
    
    assert_equal [1, 2], env['order']
  end

  def test_show_exceptions
    app = EksCent::Builder.new do
      use EksCent::Middleware::ShowExceptions
      run lambda { |env| raise "Error maut!" }
    end.to_app

    status, _headers, body = EksCent::MockRequest.new(app).get('/')
    assert_equal 500, status
    assert body.first.include?("Error maut!")
  end

  def test_builder_parse_file
    # Create temp .eks file
    File.write('test_app.eks', "run lambda { |env| [200, {}, ['File OK']] }")
    app = EksCent::Builder.parse_file('test_app.eks')
    
    status, _headers, body = EksCent::MockRequest.new(app).get('/')
    assert_equal 200, status
    assert_equal ['File OK'], body
    
    File.delete('test_app.eks')
  end
end
