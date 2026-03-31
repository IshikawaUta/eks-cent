require 'cgi'
require 'time'

module EksCent
  class Response
    attr_accessor :status, :headers, :body, :request

    def initialize(body = [], status = 200, headers = {}, request: nil)
      @status = status
      @headers = { 'Content-Type' => 'text/html' }.merge(headers)
      @body = body.is_a?(String) ? [body] : body
      @request = request
    end

    def write(str)
      @body << str
    end

    def set_header(key, value)
      @headers[key] = value
    end

    def content_type=(type)
      @headers['Content-Type'] = type
    end

    def redirect(target, status = 302)
      @status = status
      @headers['Location'] = target
    end

    def set_cookie(name, value, options = {})
      @cookies ||= {}
      @cookies[name] = options.merge(value: value)
    end

    def render(template_name, layout: true, **locals)
      require 'erb'
      template_path = File.join('views', "#{template_name}.erb")
      unless File.file?(template_path)
        raise "Template tidak ditemukan: #{template_path}"
      end

      template_content = File.read(template_path)
      
      # Gunakan context khusus agar helper h (escape HTML) tersedia
      context = Object.new
      context.extend(ERB::Util)
      
      # Suntikkan objek internal
      context.instance_variable_set("@req", @request) if @request
      context.instance_variable_set("@res", self)
      
      # Suntikkan locals
      locals.each { |k, v| context.instance_variable_set("@#{k}", v) }
      
      # Definisikan metode helper h secara eksplisit untuk keamanan
      def context.h(s); CGI.escapeHTML(s.to_s); end

      # Render template utama
      result = ERB.new(template_content).result(context.instance_eval { binding })

      # Dukungan Layout (default mencari views/layout.erb)
      if layout
        layout_name = layout == true ? 'layout' : layout.to_s
        layout_path = File.join('views', "#{layout_name}.erb")
        
        if File.file?(layout_path)
          context.instance_variable_set("@content", result)
          layout_content = File.read(layout_path)
          result = ERB.new(layout_content).result(context.instance_eval { binding })
        end
      end

      @headers['Content-Type'] ||= 'text/html'
      @body << result
    end

    def finish
      if @cookies
        @cookies.each do |name, opts|
          cookie = "#{name}=#{CGI.escape(opts[:value].to_s)}"
          cookie << "; expires=#{opts[:expires].httpdate}" if opts[:expires].is_a?(Time)
          cookie << "; path=#{opts[:path]}" if opts[:path]
          cookie << "; domain=#{opts[:domain]}" if opts[:domain]
          cookie << "; secure" if opts[:secure]
          cookie << "; httponly" if opts[:httponly]
          cookie << "; samesite=#{opts[:samesite]}" if opts[:samesite]
          
          if @headers['Set-Cookie']
            @headers['Set-Cookie'] = [@headers['Set-Cookie'], cookie].flatten
          else
            @headers['Set-Cookie'] = cookie
          end
        end
      end
      [@status, @headers, @body]
    end

    def self.build
      res = new
      yield(res)
      res.finish
    end
  end
end
