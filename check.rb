# Buat file check.rb
require_relative 'lib/eks-cent'

# 1. Muat aplikasi dari config.eks
app = EksCent.load('config.eks')

# 2. Gunakan MockRequest untuk simulasi
mock = EksCent::MockRequest.new(app)

puts "--- Cek Halaman Utama ---"
status, _headers, body = mock.get('/')
puts "Status: #{status}"
puts "Body: #{body.join}"

puts "\n--- Cek Halaman Hello dengan Parameter ---"
status, _headers, body = mock.get('/hello?name=Antigravity')
puts "Status: #{status}"
puts "Body: #{body.join}"

puts "\n--- Cek Halaman Error (Middleware ShowExceptions) ---"
status, _headers, _body = mock.get('/error')
puts "Status: #{status}"
# (Ini akan menampilkan kode HTML halaman error yang rapi)
