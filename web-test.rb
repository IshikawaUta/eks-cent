require 'webrick'
require_relative 'lib/eks-cent'

app = EksCent.load('config.eks')

server = WEBrick::HTTPServer.new(Port: 8888)
server.mount_proc '/' do |req, res|
  # Konversi WEBrick request ke format env (Rack-style)
  env = req.meta_vars.merge('rack.input' => req.body_reader)
  status, headers, body = app.call(env)
  
  res.status = status
  headers.each { |k, v| res[k] = v }
  res.body = body.join
end

puts "Server berjalan di http://localhost:8888"
trap('INT') { server.shutdown }
server.start
