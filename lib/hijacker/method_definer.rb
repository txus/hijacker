module Hijacker
  module MethodDefiner

    def define_hijacked(methods, receiver, uri)
      methods.each do |met|
        receiver.send(:alias_method, :"__original_#{met}", :"#{met}")
        receiver.send(:undef_method, :"#{met}")
        writer = (met =~ /=$/)
        receiver.class_eval <<EOS
          def #{met}(#{writer ? 'arg' : '*args, &blk'})
            _args = #{writer ? '[arg]' : 'args'}
            _args += [blk] if block_given?
            begin
              __original_#{met}(#{writer ? 'arg' : '*args, &blk'}).tap do |retval|
                Hijacker.register :#{met}, _args, retval, nil, self, #{uri.inspect}
              end
            rescue=>error
              Hijacker.register :#{met}, _args, nil, error, self, #{uri.inspect}
              raise error
            end
          end
EOS
      end
    end

  end
end
