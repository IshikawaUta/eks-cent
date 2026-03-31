module EksCent
  module Middleware
    class MethodOverride
      HTTP_METHODS = %w(GET HEAD POST PUT DELETE PATCH OPTIONS LINK UNLINK)
      METHOD_OVERRIDE_PARAM_KEY = "_method"
      HTTP_METHOD_OVERRIDE_HEADER = "HTTP_X_HTTP_METHOD_OVERRIDE"

      def initialize(app)
        @app = app
      end

      def call(env)
        if env["REQUEST_METHOD"] == "POST"
          method = method_from_env(env)
          if method && HTTP_METHODS.include?(method.upcase)
            env["eks_cent.original_method"] = env["REQUEST_METHOD"]
            env["REQUEST_METHOD"] = method.upcase
          end
        end

        @app.call(env)
      end

      private

      def method_from_env(env)
        # 1. Cek dari header X-HTTP-Method-Override
        return env[HTTP_METHOD_OVERRIDE_HEADER] if env[HTTP_METHOD_OVERRIDE_HEADER]

        # 2. Cek dari parameter body (_method)
        req = Request.new(env)
        return req.params[METHOD_OVERRIDE_PARAM_KEY] if req.params[METHOD_OVERRIDE_PARAM_KEY]

        nil
      end
    end
  end
end
