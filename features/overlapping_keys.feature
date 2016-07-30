Feature: file sources with potentially overlapping keys
  In order to guard against human error
  cmdb should fail if two sources have the same prefix

  Background:
    Given a trivial app
    And a file source "/var/lib/cmdb1/app1.json" containing:
    """
    {"hello": "world"}
    """

  Scenario: disallow overlap
    And a file source "/var/lib/cmdb2/app1.json" containing:
    """
    {"alas": "friends"}
    """
    And RACK_ENV is "production"
    When I run the shim with argv "--rewrite=."
    Then the shim should fail
