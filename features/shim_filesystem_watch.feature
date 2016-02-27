Feature: shim filesystem watch
  In order to facilitate debugging
  The CMDB shim should SIGHUP the app whenever its code changes
  So the app server can reload the fresh code

  Background:
    Given a trivial app
    And an etc file "common.yml" containing:
    """
    debug:
      enabled: true
    """

  Scenario: signal when a file is changed
    Given a shim with parameters "--reload=common.debug.enabled" running webrick
    When I touch "Gemfile"
    Then the output should include "I got a SIGHUP"

  Scenario: ignore dotfiles
    Given a shim with parameters "--reload=common.debug.enabled" running webrick
    When I touch ".some_stupid_dotfile"
    Then the output should not include "I got a SIGHUP"

  Scenario: custom signal
    Given a shim with parameters "--reload=common.debug.enabled --reload-signal=USR2" running webrick
    When I touch "Gemfile"
    Then the output should include "I got a SIGUSR2"

  Scenario: sudden death
    Given a startup bug in the app
    And a shim with parameters "--reload=common.debug.enabled --reload-signal=USR2" running webrick
    Then the shim exitstatus should be 42
