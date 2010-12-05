module Hijacker
  class << self
    def configure(&block)
      self.instance_eval(&block)
    end

    def uri(drb)
      @@drb_uri = drb
    end

    def drb_uri
      begin
        @@drb_uri
      rescue NameError
        raise UndefinedUriError, "Neither a global nor a local Hijacker server URI is configured. Please refer to the README to find out how to do this."
      end
    end
  end
end
