module EksCent
  class Builder
    def initialize(&block)
      @use = []
      @run = nil
      instance_eval(&block) if block_given?
    end

    def use(middleware, *args, **kwargs, &block)
      @use << proc { |app| middleware.new(app, *args, **kwargs, &block) }
    end

    def run(app)
      @run = app
    end

    def map(path, &block)
      @map ||= {}
      @map[path] = self.class.new(&block).to_app
    end

    def cascade(*apps)
      require_relative 'cascade' unless defined?(EksCent::Cascade)
      @run = Cascade.new(apps)
    end

    def to_app
      if @map
        require_relative 'url_map' unless defined?(EksCent::URLMap)
        @map['/'] = @run if @run
        @run = URLMap.new(@map)
      end

      app = @run
      raise "Aplikasi tidak ditemukan (run nil)" unless app
      @use.reverse_each { |middleware| app = middleware.call(app) }
      app
    end

    def self.parse_file(file)
      content = File.read(file)
      builder = new
      builder.instance_eval(content, file)
      builder.to_app
    end

    # Helper for Eks-style interface call
    def call(env)
      to_app.call(env)
    end
  end
end
