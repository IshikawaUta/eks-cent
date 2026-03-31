module EksCent
  class Cascade
    def initialize(apps = [])
      @apps = apps
    end

    def call(env)
      last_response = [404, { 'Content-Type' => 'text/plain' }, ["Not Found"]]
      
      @apps.each do |app|
        status, headers, body = app.call(env)
        
        # Jika bukan 404, atau header X-Cascade tidak bernilai 'pass', kembalikan respons ini
        if status.to_i != 404 && headers['X-Cascade'] != 'pass'
          return [status, headers, body]
        end
        
        last_response = [status, headers, body]
      end
      
      last_response
    end
  end
end
