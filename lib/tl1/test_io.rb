# frozen_string_literal: true

module TL1
  # A simple IO-like object that accepts a hash of string inputs and
  # corresponding outputs, useful for testing.
  class TestIO
    def initialize(commands, first_output: '')
      commands.each_pair do |input, output|
        next if output =~ COMPLD
        raise ArgumentError, "incomplete output for #{input}"
      end

      @commands = commands
      @next_output = first_output
    end

    def expect(pattern, _timeout = nil)
      unless pattern =~ @next_output
        raise TimeoutError, 'pattern does not match the next output'
      end

      @next_output
    end

    def write(message)
      @next_output = @commands.fetch(message)
      true
    end

    class TimeoutError < RuntimeError; end
  end # class TestIO
end # module TL1
