# frozen_string_literal: true

require 'strscan'

module TL1
  # A representation of a CLI interaction, including an input message format and
  # an output message format.
  class Command
    attr_reader :input_format, :output_format

    def initialize(input, output = nil)
      @input_format = TL1::InputFormat.new(input)
      @output_format = output && TL1::OutputFormat.new(output)
    end

    def input(**kwargs)
      input_format.format(**kwargs) + ';'
    end

    def record_sources(output)
      OutputScanner.new(output).records
    end

    def parse_output(output)
      return output unless output_format

      record_sources(output).map do |record_source|
        output_format.parse(record_source)
      end
    end

    # A helper class to extract records from output messages. Assumes records
    # are double-quoted and separated by newlines.
    class OutputScanner
      attr_reader :message

      def initialize(message)
        @message = message
      end

      def records
        records = []
        scanner = StringScanner.new(message)
        scan_begin(scanner)
        loop do
          record = scan_next_record(scanner)
          break unless record
          records << record
        end
        records
      end

      def scan_begin(scanner)
        scanner.skip_until(/^M\s+\d+\s+COMPLD$/)
      end

      def scan_next_record(scanner)
        scanner.skip(/\s*/)
        char = scanner.getch
        case char
        when '>'
          scan_begin(scanner)
          scan_next_record(scanner)
        when ';'
          nil
        when '"'
          scan_record(scanner)
        end
      end

      def scan_characters(scanner)
        loop do
          raise 'Unexpected end of message' if scanner.eos?
          yield scanner.getch
        end
      end

      def scan_record(scanner)
        record = +''

        scan_characters(scanner) do |char|
          case char
          when '\\'
            next_char = scanner.getch
            if next_char == '"'
              record << "\"#{scan_record_quoted_string(scanner)}"
            else
              record << char << next_char
            end
          when '"'
            return record
          else
            record << char
          end
        end
      end

      def scan_record_quoted_string(scanner)
        record = +''

        scan_characters(scanner) do |char|
          case char
          when '\\'
            next_char = scanner.getch
            return "#{record}\"" if next_char == '"'
            record << char << next_char
          else
            record << char
          end
        end
      end
    end
  end # class Command
end # module TL1
