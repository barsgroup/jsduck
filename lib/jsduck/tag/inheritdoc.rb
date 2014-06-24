require "jsduck/tag/tag"
require "jsduck/member_registry"

module JsDuck::Tag
  class Inheritdoc < Tag
    def initialize
      @pattern = ["inheritdoc", "inheritDoc"]
      @tagname = :inheritdoc
    end

    # @inheritdoc class.name#static-type-member
    def parse_doc(p, pos)
      parse_as_inheritdoc(p)
    end

    # This separate method exits to allow it to be also called from
    # @alias tag implementation.
    #
    # Matches a member reference: <class.name> "#" <static> "-" <type> "-" <member>
    #
    # Returns :inheritdoc tag definition with corresponding fields.
    def parse_as_inheritdoc(p)
      tag = {
        :tagname => :inheritdoc,
        :cls => p.ident_chain,
      }
      
      if p.look(/#\p{Word}/)
        p.match(/#/)
        if p.look(/static-/)
          tag[:static] = true
          p.match(/static-/)
        end
        if p.look(JsDuck::MemberRegistry.regex)
          tag[:type] = p.match(/\p{Word}+/).to_sym
          p.match(/-/)
        end
        tag[:member] = p.ident
      end

      tag
    end

    def process_doc(h, docs, pos)
      h[:inheritdoc] = docs.first
    end
  end
end
