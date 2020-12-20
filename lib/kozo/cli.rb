# frozen_string_literal: true

require "optparse"

module Kozo
  class CLI
    attr_reader :options, :parser, :args, :command_args

    def initialize(args)
      @options = {
        verbose: false,
      }

      @parser = OptionParser.new("#{$PROGRAM_NAME} [global options] command [command options]") do |o|
        o.on("Global options:")
        o.on("-v", "--verbose", "Turn on verbose logging")
        o.on("-h", "--help", "Display this message") { abort(o.to_s) }
        o.separator "\n"
        o.on("Commands:")
        commands.each { |(name, description)| o.on("    #{name}#{description.rjust(48)}") }
      end

      @args = args
      @command_args = []

      parse!
    end

    def parse!
      # Parse command line arguments (in order) and extract non-option arguments
      # (unrecognized option values). Raise for invalid option arguments (unrecognized
      # option keys). "--foo FOO --bar BAR" will result in "--foo" and "FOO" being parsed
      # correctly, "--bar" and "BAR" will be extracted.
      parser.order!(args, into: options) { |value| command_args << value }
    rescue OptionParser::InvalidOption => e
      @command_args += e.args
      retry
    end

    def start
      command = command_args.shift

      Command
        .const_get(command.camelize)
        .new(command_args, options)
        .start
    rescue NameError
      abort(parser.to_s)
    end

    private

    def commands
      Commands::Base.descendants.map { |k| [k.name.demodulize.underscore, k.description] }
    end
  end
end
