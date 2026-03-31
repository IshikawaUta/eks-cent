module EksCent
  class Router
    def initialize(&block)
      @routes = {
        'GET' => [],
        'POST' => [],
        'PUT' => [],
        'PATCH' => [],
        'DELETE' => []
      }
      @prefix = ''
      @current_middlewares = []
      @not_found_block = nil
      @error_block = nil
      instance_eval(&block) if block_given?
    end

    def not_found(&block)
      @not_found_block = block
    end

    def error(&block)
      @error_block = block
    end

    def halt(res, status = nil, body = nil)
      res.status = status if status
      res.write(body) if body
      throw(:halt)
    end

    def get(path, &block)    add_route('GET', path, &block) end
    def post(path, &block)   add_route('POST', path, &block) end
    def put(path, &block)    add_route('PUT', path, &block) end
    def patch(path, &block)  add_route('PATCH', path, &block) end
    def delete(path, &block) add_route('DELETE', path, &block) end

    def namespace(prefix, &block)
      old_prefix = @prefix
      @prefix = "#{old_prefix}#{prefix}"
      instance_eval(&block)
      @prefix = old_prefix
    end

    def group(middlewares: [], &block)
      old_middlewares = @current_middlewares
      @current_middlewares = old_middlewares + middlewares
      instance_eval(&block)
      @current_middlewares = old_middlewares
    end

    def call(env)
      req = Request.new(env)
      
      route = find_route(req)
      
      if route
        # Extract params from path
        match_data = route[:regex].match(req.path)
        params = {}
        route[:keys].each_with_index do |key, index|
          params[key] = match_data[index + 1]
        end
        
        # Inject params to env so they are available to all request objects
        env['eks_cent.router_params'] = params
        
        # Wrapped application with route-specific middlewares
        app = proc do |e| 
          req_i = Request.new(e)
          res_i = Response.new(request: req_i)
          begin
            catch(:halt) do
              instance_exec(req_i, res_i, &route[:block])
            end
          rescue => err
            if @error_block
              res_i.status = 500
              instance_exec(err, req_i, res_i, &@error_block)
            else
              raise err
            end
          end
          res_i.finish
        end
        route[:middlewares].reverse_each { |m| app = m.new(app) }
        
        _status, headers, body = app.call(env)
        [_status, headers, body]
      else
        handle_not_found(env)
      end
    end

    private

    def handle_not_found(env)
      req = Request.new(env)
      res = Response.new(request: req)
      res.status = 404

      if @not_found_block
        instance_exec(req, res, &@not_found_block)
        res.finish
      elsif File.exist?(File.join('views', '404.erb'))
        res.render '404'
        res.finish
      else
        [404, { 'Content-Type' => 'text/plain' }, ["Not Found"]]
      end
    end

    def add_route(method, path, &block)
      keys = []
      full_path = "#{@prefix}#{path}".gsub('//', '/')
      pattern = full_path.gsub(/:([\w\d_]+)/) do
        keys << $1
        "([^/]+)"
      end
      regex = /^#{pattern}$/
      
      @routes[method] << {
        path: full_path,
        regex: regex,
        keys: keys,
        middlewares: @current_middlewares.dup,
        block: block
      }
    end

    def find_route(req)
      method_routes = @routes[req.request_method]
      return nil unless method_routes
      
      method_routes.find { |route| route[:regex].match?(req.path) }
    end
  end
end
