require 'fortitude/tag_support'

module Fortitude
  class Tag
    attr_reader :name

    def initialize(name, options = { })
      @name = name.to_s.strip.downcase.to_sym
      @options = options

      # @options.assert_valid_keys([ ])
    end

    CONCAT_METHOD = "original_concat"

    def define_method_on!(mod, options = { })
      mod.send(:include, ::Fortitude::TagSupport) unless mod.respond_to?(:fortitude_tag_support_included?) && mod.fortitude_tag_support_included?

      define_constant_string(mod, :ALONE, "<#{name}/>")
      define_constant_string(mod, :OPEN, "<#{name}>")
      define_constant_string(mod, :CLOSE, "</#{name}>")
      define_constant_string(mod, :PARTIAL_OPEN, "<#{name}")

      options[:enable_formatting] = true

      method_text = <<-EOS
      def #{name}(content_or_attributes = nil, attributes = nil)
        o = @_fortitude_output_buffer_holder.output_buffer

EOS

      do_yield = "yield"
      needs_newline = options[:enable_formatting] && @options[:newline_before]
      if needs_newline
        method_text << <<-EOS
        $stderr.puts "starting #{name}"
        rc = @_fortitude_rendering_context
        format_output = rc.format_output?
        rc.newline! if format_output
EOS
        do_yield = "if format_output then $stderr.puts \'starting block inside #{name}\'; rc.newline_and_indent!; begin; yield; ensure; $stderr.puts 'ending block inside #{name}'; rc.newline_and_unindent!; end; else yield; end"
      end

      method_text << <<-EOS
        if (! content_or_attributes)
          if block_given?
            o.#{CONCAT_METHOD}(#{string_const_name(:OPEN)})
            #{do_yield}
            o.#{CONCAT_METHOD}(#{string_const_name(:CLOSE)})
          else
            o.#{CONCAT_METHOD}(#{string_const_name(:ALONE)})
          end
        elsif content_or_attributes.kind_of?(Hash)
          o.#{CONCAT_METHOD}(#{string_const_name(:PARTIAL_OPEN)})
          content_or_attributes.fortitude_append_as_attributes(o, nil)

          if block_given?
            o.#{CONCAT_METHOD}(FORTITUDE_TAG_PARTIAL_OPEN_END)
            #{do_yield}
            o.#{CONCAT_METHOD}(#{string_const_name(:CLOSE)})
          else
            o.#{CONCAT_METHOD}(FORTITUDE_TAG_PARTIAL_OPEN_ALONE_END)
          end
        elsif (! attributes)
          o.#{CONCAT_METHOD}(#{string_const_name(:OPEN)})
          content_or_attributes.to_s.fortitude_append_escaped_string(o)
          #{do_yield} if block_given?
          o.#{CONCAT_METHOD}(#{string_const_name(:CLOSE)})
        else
          o.#{CONCAT_METHOD}(#{string_const_name(:PARTIAL_OPEN)})
          attributes.fortitude_append_as_attributes(o, nil)
          o.#{CONCAT_METHOD}(FORTITUDE_TAG_PARTIAL_OPEN_END)

          content_or_attributes.to_s.fortitude_append_escaped_string(o)
          #{do_yield} if block_given?
          o.#{CONCAT_METHOD}(#{string_const_name(:CLOSE)})
        end
EOS

      if needs_newline
        method_text << <<-EOS
        if format_output
          rc.newline!
        end
EOS
      end

      method_text << <<-EOS
      end
EOS

      $stderr.puts "EVAL: #{method_text}"

      mod.module_eval(method_text)
    end

    private
    def string_const_name(key)
      "FORTITUDE_TAG_#{name.upcase}_#{key}".to_sym
    end

    def define_constant_string(target_module, key, value)
      const_name = string_const_name(key)
      target_module.send(:remove_const, const_name) if target_module.const_defined?(const_name)
      target_module.const_set(const_name, value.freeze)
    end
  end
end
