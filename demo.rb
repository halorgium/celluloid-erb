require 'celluloid'
require 'erb'
require 'pry'

module Celluloid
  # A proxy which creates future calls to an actor
  class ViewProxy < AbstractProxy
    def initialize(actor)
      @actor = actor
    end

    def inspect
      "#<Celluloid::ViewProxy>"
    end

    def timeout(value, &block)
      original_timeout = @timeout
      @timeout = value
      yield
    ensure
      @timeout = original_timeout
    end

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      future = @actor.future(meth, *args, &block)
      def future.to_s
        value
      end
      if @timeout
        @actor.after(@timeout) do
          ::Celluloid.logger.info "timeout for #{future.inspect}"
          error = ::Celluloid::TimeoutError.new("timeout")
          error.set_backtrace(caller)
          future.cancel(error)
        end
      end
      future
    end
  end
end

class Foo
  include Celluloid
  include Celluloid::Logger

  def fast
    build 2, "fast"
  end

  def slow
    build 5, "slow"
  end

  def build(timeout, name)
    info "sleep for #{timeout.inspect}"
    sleep timeout
    info "slept for #{timeout.inspect}"
    "awesome #{name}"
  end
end

foo = Celluloid::ViewProxy.new(Foo.new)

slow = foo.timeout(3) do
  foo.slow
end
fast = foo.fast

template = ERB.new(File.read(File.expand_path("../demo.erb", __FILE__)), nil, "-")
template.filename = "templates:demo.erb"
Celluloid.logger.info "starting to render"

begin
  puts template.result(binding)
rescue
  Celluloid.logger.error "got an error: #{$!.inspect}"
  raise
end
