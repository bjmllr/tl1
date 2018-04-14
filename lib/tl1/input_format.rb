# frozen_string_literal: true

module TL1
  # A format for an input message.
  class InputFormat
    attr_reader :source

    def initialize(source)
      @source = source
    end

    def ast
      @ast ||= AST.parse_message_format(source)
    end

    def as_json
      ast.as_json
    end

    def format(**kwargs)
      ast.format(**kwargs)
    end
  end # class OutputFormat
end # module TL1
