module ActiveInteraction
  class Base
    extend  ::ActiveModel::Naming
    include ::ActiveModel::Conversion
    include ::ActiveModel::Validations

    def new_record?
      true
    end

    def persisted?
      false
    end

    attr_reader :response

    def initialize(options = {})
      if options.has_key?(:response)
        raise ArgumentError, ':response is reserved and can not be used'
      end

      options.each do |attribute, value|
        if respond_to?("#{attribute}=")
          send("#{attribute}=", value)
        else
          instance_variable_set("@#{attribute}", value)
        end
      end
    end

    def execute
      raise NotImplementedError
    end

    def self.run(options = {})
      me = new(options)

      me.instance_variable_set(:@response, me.execute) if me.valid?

      me
    end

    def self.run!(options = {})
      outcome = run(options)

      if !outcome.valid?
        raise InteractionInvalid
      end

      outcome
    end

    def self.method_missing(attr_type, *args, &block)
      klass = ActiveInteraction::Attr.factory(attr_type)

      options = {}
      if args.last.is_a?(Hash)
        options = args.pop
      end
      method_names = args

      method_names.each do |method_name|
        attr_reader method_name

        define_method("#{method_name}=") do |value|
          instance_variable_set("@#{method_name}",
            klass.prepare(method_name, value, options, &block))
        end
      end
    end
    private_class_method :method_missing
  end
end