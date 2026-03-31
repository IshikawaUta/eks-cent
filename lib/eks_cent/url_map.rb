module EksCent
  class URLMap
    def initialize(map = {})
      @mapping = map.map do |path, app|
        [path.chomp('/'), app]
      end.sort_by { |path, _| -path.length } # Sort by longest path first
    end

    def call(env)
      path_info = env['PATH_INFO'] || ''
      script_name = env['SCRIPT_NAME'] || ''

      @mapping.each do |path, app|
        next unless path_info.start_with?(path)
        next unless path_info == path || path_info[path.length] == '/'

        # Matched path: shift script_name and path_info
        new_env = env.dup
        new_env['SCRIPT_NAME'] = script_name + path
        new_env['PATH_INFO'] = path_info[path.length..-1].to_s
        new_env['PATH_INFO'] = '/' if new_env['PATH_INFO'].empty?

        return app.call(new_env)
      end

      [404, { 'Content-Type' => 'text/plain', 'X-Cascade' => 'pass' }, ["Not Found (URLMap)"]]
    end
  end
end
