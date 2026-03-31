require 'test/unit'
require 'stringio'
require 'rack'
require 'fileutils'
require_relative '../lib/eks-cent'

class NewFeaturesTest < Test::Unit::TestCase
  def setup
    # Setup views directory for layout tests
    FileUtils.mkdir_p('views')
    
    # Backup file asli jika ada
    @backups = {}
    ['test.erb', 'layout.erb', '404.erb'].each do |f|
      path = File.join('views', f)
      @backups[f] = File.read(path) if File.exist?(path)
    end

    File.write('views/test.erb', "Template: <%= @name %>")
    File.write('views/layout.erb', "Layout [ <%= @content %> ] @req is <%= @req ? 'present' : 'absent' %>")
    File.write('views/404.erb', "Custom 404 Page")
  end

  def teardown
    # Hapus file sementara yang dibuat
    ['test.erb', 'layout.erb', '404.erb'].each do |f|
      path = File.join('views', f)
      File.delete(path) if File.exist?(path)
      
      # Kembalikan file asli dari backup
      File.write(path, @backups[f]) if @backups[f]
    end
    
    # Hanya hapus direktori jika kosong (tidak merusak file lain)
    Dir.rmdir('views') rescue nil
  end

  def test_halt_mechanism
    router = EksCent::Router.new do
      get '/halt' do |req, res|
        halt res, 403, "Akses Ditolak"
        res.write "Baris ini tidak boleh dieksekusi"
      end
    end

    env = { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/halt' }
    status, _headers, body = router.call(env)

    assert_equal 403, status
    assert_equal ["Akses Ditolak"], body
    assert_false body.include?("Baris ini tidak boleh dieksekusi")
  end

  def test_custom_not_found
    router = EksCent::Router.new do
      not_found do |req, res|
        res.write "Halaman Hilang"
      end
    end

    env = { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/missing' }
    status, _headers, body = router.call(env)

    assert_equal 404, status
    assert_equal ["Halaman Hilang"], body
  end

  def test_automatic_404_erb
    router = EksCent::Router.new do
      # Tidak ada blok not_found kustom
    end

    env = { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/missing' }
    status, _headers, body = router.call(env)

    assert_equal 404, status
    # Sekarang 404 akan dirender menggunakan layout secara default jika ada views/layout.erb
    assert_match(/Layout \[ Custom 404 Page \] @req is present/, body.first)
  end

  def test_layout_and_context_injection
    router = EksCent::Router.new do
      get '/render' do |req, res|
        res.render 'test', name: 'Antigravity'
      end
    end

    env = { 'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/render' }
    status, _headers, body = router.call(env)

    assert_equal 200, status
    # Harus mencakup Layout, Content, dan verifikasi @req present
    assert_match(/Layout \[ Template: Antigravity \] @req is present/, body.first)
  end

  def test_multipart_parsing
    # Simulasi request multipart
    boundary = "AaB03x"
    input_str = <<~EOF.gsub("\n", "\r\n")
      --#{boundary}
      Content-Disposition: form-data; name="title"
      
      Judul Postingan
      --#{boundary}
      Content-Disposition: form-data; name="image"; filename="test.jpg"
      Content-Type: image/jpeg
      
      (data gambar palsu)
      --#{boundary}--
    EOF

    input = StringIO.new(input_str)
    env = {
      'REQUEST_METHOD' => 'POST',
      'PATH_INFO' => '/upload',
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}",
      'CONTENT_LENGTH' => input_str.length.to_s,
      'eks.input' => input
    }

    router = EksCent::Router.new do
      post '/upload' do |req, res|
        res.write "Title: #{req.params['title']}, Image: #{req.params['image'][:filename]}"
      end
    end

    status, _headers, body = router.call(env)

    assert_equal 200, status
    assert_match(/Title: Judul Postingan, Image: test\.jpg/, body.first)
  end
end
