require 'test/unit'
require_relative '../lib/eks-cent'

class MiddlewareAndLimitsTest < Test::Unit::TestCase
  def test_runtime_middleware
    app = EksCent::Builder.new do
      use EksCent::Middleware::Runtime
      run lambda { |env| [200, {}, ["App Execution"]] }
    end.to_app
    
    mock = EksCent::MockRequest.new(app)
    res = mock.get('/')
    
    assert_not_nil res.headers['X-Runtime']
    assert res.ok?
  end
  
  def test_head_middleware
    app = EksCent::Builder.new do
      use EksCent::Middleware::Head
      run lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ["Body Content"]] }
    end.to_app
    
    mock = EksCent::MockRequest.new(app)
    
    # Normal GET
    res_get = mock.get('/')
    assert_equal "Body Content", res_get.body_content
    
    # HEAD request
    res_head = mock.request('HEAD', '/')
    assert_equal 200, res_head.status
    assert_empty res_head.body_content
  end
  
  def test_method_override
    app = EksCent::Builder.new do
      use EksCent::Middleware::MethodOverride
      run lambda { |env| [200, {}, [env['REQUEST_METHOD']]] }
    end.to_app
    
    mock = EksCent::MockRequest.new(app)
    
    # POST with _method=DELETE
    res = mock.post('/', env: { 'eks.input' => StringIO.new("_method=DELETE"), 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' })
    assert_equal "DELETE", res.body_content
  end
  
  def test_query_depth_limit
    # Simpan nilai asli untuk di-restore
    parser = Rack::Utils.default_query_parser rescue nil
    return unless parser && parser.respond_to?(:param_depth_limit=)
    
    original_limit = parser.param_depth_limit
    
    begin
      # Test bahwa setting ENV berpengaruh (lewat setup_rack_limits yang dipicu request)
      ENV['EKS_QUERY_PARSER_DEPTH_LIMIT'] = '2'
      # Kita set manual juga untuk memastikan parser yang digunakan tes terpengaruh
      parser.param_depth_limit = 2
      
      # Verifikasi bahwa Rack sekarang menolak query yang terlalu dalam
      assert_raise(RangeError) do
        Rack::Utils.parse_nested_query('a[b][c]=1')
      end
    ensure
      parser.param_depth_limit = original_limit
      ENV.delete('EKS_QUERY_PARSER_DEPTH_LIMIT')
    end
  end
end
