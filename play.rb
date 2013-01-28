$DEBUG=true
load 'lib/dbus.rb'

class NmBus
  SERVICE = "org.freedesktop.NetworkManager"
  OBJECT  = "/org/freedesktop/NetworkManager"

  attr_reader :service, :object, :internals

  def initialize
    @service = DBus.system_bus.service SERVICE
    @object  = @service.object OBJECT
  end

  def introspect
    Thread.new do
      @internals = @object.introspect
    end
  end

  def devices_threads that_many
    object.introspect
    stop = 4
    threads = []
    that_many.times do |i|
      threads << Thread.new do
        sleep rand(stop)
        puts "#{i}. #{object.GetDevices}\n\n"
      end
    end
    threads.each &:join
  end

  def devices_serial count
    object.introspect
    count.times do |i|
      puts "#{i}. #{object.GetDevices}"
    end
  end

  def rocket n
    threads = []
    n.times do |i|
      threads << Thread.new do
        sleep rand(2)
        puts "THIS IS #{i}"
        ser = DBus.system_bus.service SERVICE
        obj = service.object OBJECT
        obj.introspect
        obj.GetDevices
      end
      threads.join
    end
  end
end

def nm
  @nm ||= NmBus.new
end

def ping
  rp, wp = IO.pipe
  mesg = "ping "
  10.times {
    rs, ws, = IO.select([rp], [wp])
    if r = rs[0]
      ret = r.read(10)
      print ret
      case ret
      when /ping/
        mesg = "pong\n"
      when /pong/
        mesg = "ping "
      end
    end
    if w = ws[0]
      w.write(mesg)
    end
  }
end

def list_dbus_methods
  bus = DBus.system_bus
  bus.proxy.ListNames[0].reject {|m| m =~ /\A:/}.sort.each do |service|
    puts "Service: #{service}"
  end
end

class Q
  attr_reader :queue

  def initialize *elements
    @queue = Queue.new
    elements.each {|el| @queue.enq el }
  end

  def add member
    @queue.enq member
  end

  def pop
    Thread.new { @queue.pop }
  end

  def lpop
    Thread.new do
      loop do
        @queue.pop
        puts "Waited for new queue element"
      end
    end
  end
end

