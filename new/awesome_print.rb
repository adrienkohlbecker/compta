module AwesomePrint
  module ActiveModel
    def self.included(base)
      base.send :alias_method, :cast_without_active_model, :cast
      base.send :alias_method, :cast, :cast_with_active_model
    end

    def cast_with_active_model(object, type)
      cast = cast_without_active_model(object, type)
      if (defined?(::ActiveModel::Serialization)) && (object.class.included_modules.include?(::ActiveModel::Serialization))
        cast = :active_model_instance
      end
      cast
    end

    def awesome_active_model_instance(object)
      data = object.serializable_hash.inject(::ActiveSupport::OrderedHash.new) do |hash, c|
        hash[c.first.to_sym] = c.last
        hash
      end

      "#{object.class} #{awesome_hash(object.serializable_hash)}"
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::ActiveModel)
