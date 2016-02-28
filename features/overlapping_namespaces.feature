Feature: file sources with overlapping namespaces
  In order to guard against human error
  cmdb should fail if sources provide overlapping namespaces
  So apps in production never accidentally run with development-mode settings

  Background:
    Given a trivial app
    And an etc file "app1.json" containing:
    """
    {"hello": "world"}
    """

  Scenario: allow overlap in development
    Given a working-dir file "app1.json" containing:
    """
    {"alas": "friends"}
    """
    And RACK_ENV is "development"
    When I run cmdb shim with argv "--dir=."
    Then the command should succeed

  Scenario: disallow overlap in production
    Given a homedir file "app1.json" containing:
    """
    {"alas": "friends"}
    """
    And RACK_ENV is "production"
    When I run cmdb shim with argv "--dir=."
    Then the command should fail
