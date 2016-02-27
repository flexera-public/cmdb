Feature: shim drop privileges using setuid
  In order to promote security best practices
  cmdb shim should switch to www-data before running apps
  So developers can easily practice the principle of least privilege

  Background:
    Given RACK_ENV is "production"

  Scenario: run normally
    When I run the shim without "--user"
    Then the shim should not setuid
    And the shim should succeed

  Scenario: run as www-data
    When I run the shim with "--user=www-data"
    Then the shim should setuid to "www-data"
    And the shim should succeed
