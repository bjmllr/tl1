# frozen_string_literal: true
module TL1
  # A wrapper around an IO-like object representing a connection to a
  # TL1-capable network element.
  class Session
    # @param io [IO, Net::SSH::Telnet, Net::Telnet]
    #   An established connection to a TL1 server.
    #
    #   The connection object must have a `#write` method, and one of two read
    #   methods: `#expect` or `#waitfor`. If you are using Net::Telnet or
    #   Net::SSH::Telnet, `#waitfor` will be used. Otherwise, you should make
    #   sure that your connection object has an `#expect` method that behaves
    #   like `IO#expect` from the standard library.
    #
    # @param timeout [Integer]
    #   How long to wait for responses, by default.
    def initialize(io, timeout = 10)
      @timeout = timeout
      @io =
        if io.respond_to?(:expect)
          io
        elsif io.respond_to?(:waitfor)
          WaitforWrapper.new(io)
        else
          raise UnsupportedIOError,
                "the given IO doesn't respond to expect or waitfor"
        end
    end

    # Execute a TL1::Command
    #
    # @param [TL1::Command]
    # @return [TL1::AST::Node]
    def cmd(command, **kwargs)
      output = raw_cmd(command.input(**kwargs))
      command.parse_output(output)
    end

    # Receive data until the given pattern is matched.
    #
    # @param pattern [Regexp]
    # @param timeout [Integer]
    def expect(pattern, timeout = nil)
      timeout ||= @timeout
      @io.expect(pattern, timeout)
    end

    # Send a string and receive a string back.
    #
    # @param message [String]
    # @param timeout [Integer]
    # @return [String]
    def raw_cmd(message, timeout = nil)
      write(message)
      expect(COMPLD, timeout)
    end

    # Send a string.
    #
    # @param message [String]
    # @return [Boolean]
    def write(message)
      @io.write(message)
    end

    # Wraps objects that support `#waitfor` but not `#expect`, such as
    # Net::Telnet and Net::SSH::Telnet. It is used transparently by
    # `TL1::Session#initialize` for those classes, so it shouldn't be necessary
    # to use it directly. If you are defining a new class that responds to
    # `#waitfor`, you can define your own `#expect` method instead of using
    # this.
    class WaitforWrapper
      def initialize(io)
        @io = io
      end

      def expect(pattern, timeout)
        @io.waitfor('Match' => pattern, 'Timeout' => timeout)
      end

      def write(*args)
        @io.write(*args)
      end
    end # class WaitforWrapper
  end # class Session
end # module TL1
