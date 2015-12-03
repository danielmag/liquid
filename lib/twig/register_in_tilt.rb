require 'tilt'

module Tilt
  class TwigTemplate < Template
    def prepare
      @engine = ::Twig::Template.parse(data)
    end

    def evaluate(scope, locals, &block)
      locals = locals.inject({}){ |h,(k,v)| h[k.to_s] = v ; h }
      if scope.respond_to?(:to_h)
        scope  = scope.to_h.inject({}){ |h,(k,v)| h[k.to_s] = v ; h }
        locals = scope.merge(locals)
      end
      locals['yield'] = block.nil? ? '' : yield
      locals['content'] = locals['yield']
      @engine.render(locals)
    end

    def allows_script?
      false
    end

  end

  register TwigTemplate, 'twig'
end
