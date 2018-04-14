# frozen_string_literal: true

require 'strscan'

module TL1
  # Namespace for AST Nodes in input and output formats
  module AST
    module_function def parse_message_format(source)
      ColonSeparatedVariables.parse(source)
    end

    module_function def colon_separated_element(source)
      return from_json(source) if source.is_a?(Hash)
      raise "Unparseable element #{source}" unless source.is_a?(String)

      if source.include?('=')
        CommaSeparatedKeywordVariables.parse(source)
      elsif source.include?(',')
        CommaSeparatedVariables.parse(source)
      elsif source.start_with?('<') && source.end_with?('>')
        Variable.parse(source)
      else
        Literal.parse(source)
      end
    end

    module_function def from_json(source)
      node = NODES_BY_NAME.fetch(source['node']) do
        raise "Unknown node type #{source['node']}"
      end

      node.parse(source['fields'])
    end

    module_function def split(string, delimiter)
      scanner = StringScanner.new(string)
      array = [+'']

      loop do
        return array if scanner.eos?
        char = scanner.getch
        case char
        when delimiter
          array << +''
        when '"'
          array.last << split_quoted(scanner)
        else
          array.last << char
        end
      end
    end

    module_function def split_quoted(scanner)
      string = +'"'

      loop do
        raise 'Unexpected end of quoted string' if scanner.eos?
        char = scanner.getch
        case char
        when '"'
          string << '"'
          return string
        else
          string << char
        end
      end
    end

    module_function def remove_quotes(string)
      if string.start_with?('"') && string.end_with?('"')
        string[1..-2]
      else
        string
      end
    end

    # The base class for all AST nodes
    class Node
      include Comparable
      attr_reader :fields

      def <=>(other)
        return unless other.is_a?(Node)
        fields <=> other.fields
      end

      def as_json(fields = nil)
        fields ||= @fields
        { node: NODES_BY_CLASS[self.class], fields: fields }
      end

      def to_json
        as_json.to_json
      end
    end

    # A sequence of fields or groups of fields separated by colons. This is the
    # "root" AST node for every input message and every record in an output
    # message.
    class ColonSeparatedVariables < Node
      def self.parse(source)
        elements =
          if source.is_a?(String)
            AST.split(source, ':')
          else
            source.fetch('fields')
          end

        new(*elements.map { |e| AST.colon_separated_element(e) })
      end

      def initialize(*fields)
        @fields = fields
      end

      def as_json
        super(@fields.map(&:as_json))
      end

      def format(**kwargs)
        fields.map { |f| f.format(**kwargs) }.join(':')
      end

      def parse(record_source, record: {})
        pairs = AST.split(record_source, ':').zip(@fields)

        pairs.each do |fragment, node|
          node.parse(fragment, record: record)
        end

        record
      end
    end # class ColonSeparatedVariables

    # A group of fields separated by commas with a fixed order.
    class CommaSeparatedVariables < Node
      def self.parse(source)
        elements =
          if source.is_a?(String)
            AST.split(source, ',').map { |e| Variable.parse(e) }
          else
            source.map { |e| Variable.parse(e['fields']) }
          end

        new(*elements)
      end

      def initialize(*fields)
        @fields = fields
      end

      def as_json
        super(fields.map(&:as_json))
      end

      def format(**kwargs)
        fields.map { |f| f.format(**kwargs) }.join(',')
      end

      def parse(source, record:)
        AST.split(source, ',').zip(fields).each do |value, field|
          field.parse(value, record: record)
        end

        record
      end
    end # class CommaSeparatedVariables

    # A group of fields separated by commas and identified by keywords. Fields
    # may appear in any order.
    class CommaSeparatedKeywordVariables < Node
      def self.parse(source)
        elements =
          if source.is_a?(String)
            AST.split(source, ',').map { |pair|
              key, value = pair.split('=', 2)
              [key.to_s, Variable.parse(value)]
            }.to_h
          else
            source.map { |k, v| [k.to_s, Variable.parse(v['fields'])] }.to_h
          end

        new(elements)
      end

      def as_json
        super(fields.keys.zip(fields.values.map(&:as_json)).to_h)
      end

      def initialize(fields)
        @fields = fields
      end

      def format(**kwargs)
        fields.each_pair.flat_map { |keyword, variable|
          if kwargs.key?(variable.fields)
            ["#{keyword}=#{kwargs[variable.fields]}"]
          else
            []
          end
        }.join(',')
      end

      def parse(fragment, record:)
        AST.split(fragment, ',').each do |pair|
          next if pair.empty?
          key, value = pair.split('=', 2)
          field_name = @fields.fetch(key)
          record[field_name.fields] = AST.remove_quotes(value)
        end

        record
      end
    end # class CommaSeparatedKeywordVariables

    # A literal string. Not included in parsing output, but must match.
    class Literal < Node
      def self.parse(source)
        new(source)
      end

      def initialize(fields)
        @fields = fields.to_str
      end

      def format(*)
        fields
      end

      def parse(source, **)
        return if source == format
        raise "Message literal does not match format literal #{format.inspect}"
      end
    end # class Literal

    # A variable string. Included in parsing output.
    class Variable < Node
      def self.parse(source)
        new(optional_variable(source))
      end

      def self.optional_variable(token)
        token.match(/\A<(.*)>\z/) { |m| m[1].to_sym } || token.to_sym
      end

      def initialize(fields)
        @fields = fields
      end

      def format(**kwargs)
        kwargs[@fields]
      end

      def parse(fragment, record:)
        record[fields] = AST.remove_quotes(fragment)
      end
    end # class Variable

    NODES_BY_NAME = [
      ColonSeparatedVariables,
      CommaSeparatedKeywordVariables,
      CommaSeparatedVariables,
      Literal,
      Variable
    ].map { |n| [n.to_s.split('::').last, n] }.to_h.freeze

    NODES_BY_CLASS = NODES_BY_NAME.invert.freeze
  end # class AST
end # module TL1
