require 'socket'

module DebugSocket
  @@seq = 0
  def DebugSocket.open_log
    n = (@@seq += 1)
    f = File.open("/tmp/debug-socket-#{n}", 'w')
    f.sync = true
    f
  end

  class TCPSock < TCPSocket
    def initialize(host, service, *rest)
      super
      init_debugsocket(host, service)
    end

    def init_debugsocket(host=nil, service=nil)
      unless host
        address_family, port, host, address = self.peeraddr
        service ||= port
      end
      @debug_log = DebugSocket.open_log
      @debug_log << "#{host}:#{service}\n"
      @debug_rcount = 0
      @debug_wcount = 0
    end

    def debug_wdata(str)
      str.each_line {|line|
        @debug_log << @debug_wcount.to_s
        @debug_wcount += line.length
        @debug_log << ">"
        @debug_log << line.dump << "\n"
      }
    end

    def debug_rdata(str)
      return unless str
      str.each_line {|line|
        @debug_log << @debug_rcount.to_s
        @debug_rcount += line.length
        @debug_log << "<"
        @debug_log << line.dump << "\n"
      }
    end

    def write(str)
      debug_wdata(str)
      super
    end

    def syswrite(str)
      debug_wdata(str)
      super
    end

    def each(*args)
      super(*args) {|line|
        debug_rdata(line)
        yield line
      }
    end
    alias each_line each

    def each_byte(*args)
      super(*args) {|ch|
        debug_rdata([ch].pack("C"))
        yield ch
      }
    end

    def getc(*args)
      ch = super
      debug_rdata([ch].pack("C"))
      return ch
    end

    def gets(*args)
      line = super
      debug_rdata(line)
      return line
    end

    def read(*args)
      str = super
      debug_rdata(str)
      return str
    end

    def readchar(*args)
      ch = super
      debug_rdata([ch].pack("C"))
      return ch
    end

    def readline(*args)
      line = super
      debug_rdata(line)
      return line
    end

    def readlines(*args)
      lines = super
      lines.each {|line| debug_rdata(line) }
      return lines
    end

    def sysread(*args)
      str = super
      debug_rdata(str)
      return str
    end
  end
end

class << TCPSocket
  alias debugsocket_original_open open
  def open(host, service, *rest, &block)
    if self == TCPSocket
      DebugSocket::TCPSock.debugsocket_original_open(host, service, *rest, &block)
    else
      debugsocket_original_open(host, service, *rest, &block)
    end
  end

  alias debugsocket_original_new new
  def new(host, service, *rest, &block)
    if self == TCPSocket
      DebugSocket::TCPSock.debugsocket_original_new(host, service, *rest, &block)
    else
      debugsocket_original_new(host, service, *rest, &block)
    end
  end
end

class TCPServer
  alias debugsocket_original_accept accept
  def accept
    sock = DebugSocket::TCPSock.for_fd(sysaccept)
    sock.init_debugsocket
    sock
  end
end
