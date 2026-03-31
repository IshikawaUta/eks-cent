# web-test.rb
# Utilitas untuk mencatat dan menguji aplikasi Eks-Cent dengan server nyata.

require_relative 'lib/eks-cent'

# Memuat kemandirian Eksa-Server
begin
  spec = Gem::Specification.find_by_name('eksa-server')
  gem_root = spec.gem_dir
  require File.join(gem_root, 'server.rb')
rescue Gem::LoadError
  puts "\e[31mError: Gem 'eksa-server' tidak ditemukan.\e[0m"
  puts "Silakan instal dengan: gem install eksa-server"
  exit 1
end

# Memuat aplikasi dari config.eks
app = EksCent.load('config.eks')

# Opsi server
options = {
  port: 8888,
  host: '0.0.0.0',
  env: 'development'
}

puts "\e[34m[Eks-Cent Test] Menjalankan server eksa-server di http://localhost:8888\e[0m"

# Inisialisasi dan jalankan server
server = EksaServerCore.new(app, options)
server.start
