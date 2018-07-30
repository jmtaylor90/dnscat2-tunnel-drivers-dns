# Encoding: ASCII-8BIT

##
# standard.rb
# Created July, 2018
# By Ron Bowes
#
# See: LICENSE.md
##

require 'nesser'
require 'singlogger'

require 'dnscat2/tunnel_drivers/dns/encoders/hex'

module Dnscat2
  module TunnelDrivers
    module DNS
      module Readers
        ##
        # Reads the data from a DNS packet's name. This is the normal (and only)
        # reader so far.
        ##
        class Standard
          def initialize(tags:, domains:, encoder: Encoders::Hex)
            @l        = SingLogger.instance
            @tags     = tags || []
            @domains  = domains || []
            @encoder  = encoder
          end

          ##
          # Determines whether this message is intended for us (it either starts
          # with one of the 'tags' or ends with one of the domains).
          #
          # The return is a true/false value, followed by the question with the
          # extra cruft removed (just the data remaining).
          ##
          private
          def _is_this_message_for_me(name:)
            name = name.downcase

            # Check for domain first
            @domains.each do |d|
              d = d.downcase

              # Capture both the exact domain, and "dot-domain"
              if name == d || name.end_with?('.' + d)
                @l.debug("TunnelDrivers::DNS::Readers::Standard Message is for me, based on domain! #{name}")
                return nil, d, name[0...-(d.length + 1)]
              end
            end

            # Check for tags second
            @tags.each do |t|
              t = t.downcase

              # Capture both the exact domain, and "tag-dot"
              if name == t || name.start_with?(t + '.')
                @l.debug("TunnelDrivers::DNS::Readers::Standard Message is for me, based on tag! #{name}")
                return t, nil, name[(t.length + 1)..-1]
              end
            end

            return nil, nil, name
          end

          public
          def read_data(question:)
            # Get the name handy
            name = question.name

            # Either tag or domain must be set
            tag, domain, name = _is_this_message_for_me(name: name)

            if !tag && !domain
              @l.debug("TunnelDrivers::DNS::Readers::Standard Received a message that didn't match our tag or domains: #{name}")
              return nil
            end

            # Decode the name into data
            @l.debug("TunnelDrivers::DNS::Readers::Standard Decoding #{name}...")
            return @encoder.decode(data: name.delete('.')), tag, domain
          end
        end
      end
    end
  end
end
