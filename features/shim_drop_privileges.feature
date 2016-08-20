Feature: shim drop privileges using setuid
  In order to promote security best practices
  cmdb shim should switch to www-data before running apps
  So developers can easily practice the principle of least privilege

  Background:
    Given RACK_ENV is "production"

  Scenario: run normally
    When I Commands::Shim without "user:"
    Then the command should not setuid
    And the command should succeed

  Scenario: run as www-data
    When I run Commands::Shim with "user:www-data"
    Then the command should setuid to "www-data"
    And the command should succeed
