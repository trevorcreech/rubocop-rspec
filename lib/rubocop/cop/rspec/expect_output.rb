# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for opportunities to use `expect { ... }.to output`.
      #
      # @example
      #   # bad
      #   $stdout = StringIO.new
      #   my_app.print_report
      #   $stdout = STDOUT
      #   expect($stdout.string).to eq('Hello World')
      #
      #   # good
      #   expect { my_app.print_report }.to output('Hello World').to_stdout
      class ExpectOutput < Cop
        MSG = 'Use `expect { ... }.to output(...).to_%<name>s` ' \
              'instead of mutating $%<name>s'.freeze

        def_node_matcher :hook?, Hooks::ALL.block_pattern

        def on_gvasgn(node)
          return unless inside_example_scope?(node)

          variable_name, _rhs = *node
          name = variable_name[1..-1]
          return unless name.eql?('stdout') || name.eql?('stderr')

          add_offense(node, :name, format(MSG, name: name))
        end

        private

        # Detect if we are inside the scope of a single example
        #
        # We want to encourage using `expect { ... }.to output` so
        # we only care about situations where you would replace with
        # an expectation. Therefore, assignments to stderr or stdout
        # within a `before(:all)` or otherwise outside of an example
        # don't matter.
        def inside_example_scope?(node)
          return false if node.nil? || example_group?(node)
          return true if example?(node)
          return RuboCop::RSpec::Hook.new(node).example? if hook?(node)

          inside_example_scope?(node.parent)
        end
      end
    end
  end
end
