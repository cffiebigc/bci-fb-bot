require 'httparty'
require 'json'
require_relative '../ui/ui'
require_relative 'questionnaire'
require_relative 'bci_api'
require_relative 'show_ui_examples'
# Everything in this module will become private methods for Dispatch classes
# and will exist in a shared namespace.
module Commands
  # Mix-in sub-modules for threads
  include Questionnaire
  include BciApi

  # State 'module_function' before any method definitions so
  # commands are mixed into Dispatch classes as private methods.
  module_function
end
