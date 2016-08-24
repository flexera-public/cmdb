module CMDB
  module Shell
    # Maximum number of "things" before the UI starts collapsing display
    # elements, i.e. treating subtrees as subdirectories.
    FEW  = 3

    # Maximum number of "things" for which to offer autocomplete and other
    # shortcuts.
    MANY = 25
  end
end

require 'cmdb/shell/dsl'
require 'cmdb/shell/text'
require 'cmdb/shell/printer'
require 'cmdb/shell/prompter'
