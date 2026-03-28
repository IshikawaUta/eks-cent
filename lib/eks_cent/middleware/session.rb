require 'json'
require 'base64'
require 'openssl'

module EksCent
  module Middleware
    class Session
      SESSION_KEY = 'eks_cent.session'

      def initialize(app, options = {})
        @app = app
        @cookie_name = options[:cookie_name] || '_eks_cent_session'
        @secret = options[:secret] # Placeholder for future signing
      end

      def call(env)
        # 1. Load session from cookie
        load_session(env)
        
        # 2. Call the app
        status, headers, body = @app.call(env)
        
        # 3. Save session back to cookie if data exists
        if env[SESSION_KEY]
          json_data = JSON.dump(env[SESSION_KEY])
          encoded_data = Base64.strict_encode64(json_data)
          signed_data = sign(encoded_data)
          
          cookie = "#{@cookie_name}=#{signed_data}; path=/; HttpOnly"
          
          if headers['Set-Cookie']
            headers['Set-Cookie'] = [headers['Set-Cookie'], cookie].flatten
          else
            headers['Set-Cookie'] = cookie
          end
        end

        [status, headers, body]
      end

      private

      def load_session(env)
        cookie_header = env['HTTP_COOKIE']
        session_data = nil
        
        if cookie_header
          cookies = CGI::Cookie.parse(cookie_header)
          if cookies[@cookie_name] && !cookies[@cookie_name].empty?
            begin
              signed_data = cookies[@cookie_name].first
              encoded_data = verify(signed_data)
              
              if encoded_data
                session_data = JSON.parse(Base64.decode64(encoded_data))
              end
            rescue
              session_data = {}
            end
          end
        end
        
        env[SESSION_KEY] = session_data || {}
      end

      def sign(data)
        secret = EksCent.secret_key_base
        signature = OpenSSL::HMAC.hexdigest('SHA256', secret, data)
        "#{data}--#{signature}"
      end

      def verify(signed_data)
        data, signature = signed_data.split('--')
        return nil unless data && signature
        
        expected_signature = OpenSSL::HMAC.hexdigest('SHA256', EksCent.secret_key_base, data)
        
        # Gunakan constant time comparison jika tersedia (Rack::Utils), 
        # jika tidak gunakan perbandingan standar dengan aman.
        begin
          return data if Rack::Utils.secure_compare(signature, expected_signature)
        rescue
          return data if signature == expected_signature
        end
        
        nil
      end
    end
  end
end
