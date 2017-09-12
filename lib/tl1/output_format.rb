# frozen_string_literal: true
module TL1
  # A format for records appearing in output messages.
  class OutputFormat
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

    def parse(record_source)
      ast.parse(record_source)
    end
  end # class OutputFormat
end # module TL1
