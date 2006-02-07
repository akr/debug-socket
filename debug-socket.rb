require 'socket'
require 'thread'

module DebugSocket
  @@seq = 0
  def DebugSocket.open_log
    base = ENV['DEBUG_SOCKET_BASE'] || '/tmp/debug-socket'
    user = ENV['USER'] || Process.uid.to_s
    n = (@@seq += 1)
    filename = "#{base}-#{user}-#{n}"
    f = File.open(filename, File::WRONLY|File::APPEND|File::CREAT|File::TRUNC, 0600)
    s = f.stat
    raise SecurityError.new("#{filename.inspect}: unexpected owner.") unless s.owned?
    raise SecurityError.new("#{filename.inspect}: unexpected mode.") unless s.mode & 0777 == 0600
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
      @debug_lock = Mutex.new
    end

    def debug_wdata(str)
      @debug_lock.synchronize {
	str.each_line {|line|
	  @debug_log << @debug_wcount.to_s
	  @debug_wcount += line.length
	  @debug_log << ">"
	  @debug_log << line.dump << "\n"
	}
      }
    end

    def debug_rdata(str)
      return unless str
      @debug_lock.synchronize {
	str.each_line {|line|
	  @debug_log << @debug_rcount.to_s
	  @debug_rcount += line.length
	  @debug_log << "<"
	  @debug_log << line.dump << "\n"
	}
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
    if self <= TCPServer
      debugsocket_original_open(host, service, *rest, &block)
    else
      DebugSocket::TCPSock.debugsocket_original_open(host, service, *rest, &block)
    end
  end

  alias debugsocket_original_new new
  def new(host, service, *rest, &block)
    if self <= TCPServer
      debugsocket_original_new(host, service, *rest, &block)
    else
      DebugSocket::TCPSock.debugsocket_original_new(host, service, *rest, &block)
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
