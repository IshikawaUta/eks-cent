require_relative 'lib/eks-cent'

app = EksCent.load('config.eks')
mock = EksCent::MockRequest.new(app)

puts "--- Cek Rute Dinamis /hello/Budi ---"
status, _headers, body = mock.get('/hello/Budi')
puts "Status: #{status}"
puts "Body: #{body.join}"

puts "\n--- Cek Rute Dinamis /hello/Siska ---"
status, _headers, body = mock.get('/hello/Siska')
puts "Status: #{status}"
puts "Body: #{body.join}"
