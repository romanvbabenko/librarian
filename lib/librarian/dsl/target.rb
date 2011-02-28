module Librarian
  class Dsl
    class Target

      SCOPABLES = [:sources]

      attr_reader :dependency_name, :dependency_type
      attr_reader :source_types, :source_types_map, :source_type_names
      attr_reader :dependencies, *SCOPABLES

      def initialize(dependency_name, dependency_type, source_types)
        @dependency_name = dependency_name
        @dependency_type = dependency_type
        @source_types = source_types
        @source_types_map = Hash[source_types]
        @source_type_names = source_types.map{|t| t[0]}
        @dependencies = []
        SCOPABLES.each do |scopable|
          instance_variable_set(:"@#{scopable}", [])
        end
      end

      def dependency(name, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        source = source_from_options(options) || @sources.last
        unless source
          raise Error, "#{dependency_name} #{name} is specified without a source!"
        end
        dep = dependency_type.new(name, args, source)
        @dependencies << dep
      end

      def source(name, param = nil, options = {})
        name, param, options = *normalize_source_options(name, param, options)
        type = source_types_map[name]
        source = type.new(param, options)
        if !block_given?
          @sources = @sources.dup << source
        else
          scope do
            @sources = @sources.dup << source
            yield
          end
        end
      end

      private

      def scope
        currents = { }
        SCOPABLES.each do |scopable|
          currents[scopable] = instance_variable_get(:"@#{scopable}").dup
        end
        yield
      ensure
        SCOPABLES.reverse.each do |scopable|
          instance_variable_set(:"@#{scopable}", currents[scopable])
        end
      end

      def normalize_source_options(name, param, options)
        if name.is_a?(Hash)
          extract_source_parts(name)
        else
          [name, param, options]
        end
      end

      def extract_source_parts(options)
        unless name = source_type_names.find{|name| options.key?(name)}
          nil
        else
          options = options.dup
          param = options.delete(name)
          [name, param, options]
        end
      end

      def source_from_options(options)
        unless source_parts = extract_source_parts(options)
          nil
        else
          name, param, options = *source_parts
          type = source_types_map[name]
          type.new(param, options)
        end
      end

    end
  end
end
