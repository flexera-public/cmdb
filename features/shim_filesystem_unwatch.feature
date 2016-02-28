Feature: shim filesystem UNwatch
  In order to reduce downtime
  The CMDB shim should not signal the app in production-like environments
  So the app server never unexpectedly terminates

  Background:
    Given a trivial app

  Scenario: ignore changed files
    Given cmdb shim with argv "--reload=common.debug.enabled" running webrick
    And an etc file "common.yml" containing:
    """
    debug:
      enabled: false
    """
    When I touch "Gemfile"
    Then the output should not include "I got a SIGHUP"

  Scenario: ignore new files
    Given cmdb shim with argv "--reload=common.debug.enabled" running webrick
    And an etc file "common.yml" containing:
    """
    debug:
      enabled: false
    """
    When I create "app/dummy.rb" with content:
    """
    announce 'hello world'
    """
    Then the output should not include "I got a SIGHUP"

  Scenario: ignore new files
    Given cmdb shim with argv "--reload=does.not.exist" running webrick
    And an etc file "common.yml" containing:
    """
    debug:
      enabled: true
    """
    When I create "app/dummy.rb" with content:
    """
    announce 'hello world'
    """
    Then the output should not include "I got a SIGHUP"
