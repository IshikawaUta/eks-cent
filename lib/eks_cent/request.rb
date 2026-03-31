require 'uri'
require 'cgi'
require 'json'

module EksCent
  class Request
    attr_reader :env

    def initialize(env)
      @env = env
      # Map standard Rack keys to Eks branding for internal consistency
      @env['eks.input']   ||= @env['rack.input']
      @env['rack.input']  ||= @env['eks.input']
      
      @env['eks.version'] ||= @env['rack.version'] || [1, 3]
      @env['rack.version'] ||= @env['eks.version']
      
      @env['eks.errors']  ||= @env['rack.errors']
      @env['rack.errors'] ||= @env['eks.errors']
      
      @env['eks.multithread']  ||= @env['rack.multithread'] || false
      @env['eks.multiprocess'] ||= @env['rack.multiprocess'] || false
      @env['eks.run_once']     ||= @env['rack.run_once'] || false
    end

    def request_method
      @env['REQUEST_METHOD']
    end

    def path
      @env['PATH_INFO'] || '/'
    end

    def query_string
      @env['QUERY_STRING'] || ''
    end

    def params
      @params ||= parse_params
    end

    def get?
      request_method == 'GET'
    end

    def post?
      request_method == 'POST'
    end

    def user_agent
      @env['HTTP_USER_AGENT']
    end

    def cookies
      @cookies ||= parse_cookies
    end

    def session
      @env['eks_cent.session'] ||= {}
    end

    private

    def parse_cookies
      cookie_header = @env['HTTP_COOKIE']
      return {} unless cookie_header
      
      CGI::Cookie.parse(cookie_header).transform_values(&:first)
    end

    def parse_params
      require 'rack' unless defined?(Rack)
      
      # Terapkan batasan global Eks/Rack jika ada di ENV
      setup_eks_limits

      # Gunakan Rack::Request untuk menangani parsing parameter standar (GET/POST/Multipart)
      rack_req = Rack::Request.new(@env)
      params = rack_req.params.dup

      # Gabungkan dengan parameter dari router (misal: /hello/:name)
      if @env['eks_cent.router_params']
        params.merge!(@env['eks_cent.router_params'])
      end

      # Tambahkan parsing JSON manual karena Rack::Request tidak melakukannya secara otomatis
      if @env['CONTENT_TYPE'] == 'application/json' && @env['eks.input']
        begin
          body = @env['eks.input'].read
          @env['eks.input'].rewind if @env['eks.input'].respond_to?(:rewind)
          
          if body && !body.empty?
            json_params = JSON.parse(body)
            if json_params.is_a?(Hash)
              # Batasi jumlah parameter JSON jika EKS/RACK_QUERY_PARSER_PARAMS_LIMIT diatur
              limit = (ENV['EKS_QUERY_PARSER_PARAMS_LIMIT'] || ENV['RACK_QUERY_PARSER_PARAMS_LIMIT'])&.to_i || 1000
              if json_params.size > limit
                raise "Too many parameters (JSON)"
              end
              params.merge!(json_params)
            end
          end
        rescue JSON::ParserError
          # Abaikan error parsing JSON
        end
      end

      # Pastikan nilai parameter diratakan (flatten) jika berupa array berukuran 1
      # Catatan: Rack::Request mungkin sudah melakukannya untuk form data standar, 
      # tapi kita pastikan konsistensi di sini.
      params.transform_values { |v| v.is_a?(Array) && v.size == 1 ? v.first : v }
    end
    def setup_eks_limits
      return if @eks_limits_setup
      
      parser = Rack::Utils.default_query_parser rescue nil
      return unless parser

      params_limit = ENV['EKS_QUERY_PARSER_PARAMS_LIMIT'] || ENV['RACK_QUERY_PARSER_PARAMS_LIMIT']
      if params_limit && parser.respond_to?(:params_limit=)
        parser.params_limit = params_limit.to_i
      end

      bytesize_limit = ENV['EKS_QUERY_PARSER_BYTESIZE_LIMIT'] || ENV['RACK_QUERY_PARSER_BYTESIZE_LIMIT']
      if bytesize_limit && parser.respond_to?(:bytesize_limit=)
        parser.bytesize_limit = bytesize_limit.to_i
      end
      
      multipart_limit = ENV['EKS_MULTIPART_TOTAL_PART_LIMIT'] || ENV['RACK_MULTIPART_TOTAL_PART_LIMIT']
      if multipart_limit
        if Rack::Utils.respond_to?(:multipart_total_part_limit=)
          Rack::Utils.multipart_total_part_limit = multipart_limit.to_i
        end
      end
      
      @eks_limits_setup = true
    end
  end
end
