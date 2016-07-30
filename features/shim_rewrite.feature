Feature: config-file rewriting shim for legacy apps
  In order to enhance uptime and productivity
  cmdb should apply CMDB inputs to app config files
  So we can package legacy apps without retrofitting them for CMDB smarts

  Background:
    Given a trivial app
    And RACK_ENV is "production"
    And a file source "/var/lib/cmdb/app1.yml" containing:
    """
    database:
      host: db1.example.com
      user: alibaba
      password: open sesame
    """

  Scenario: simple YAML replacement
    Given an app file "config/database.yml" containing:
    """
    integration:
      host: <<app1.database.host>>
      user: <<app1.database.user>>
      password: <%= ENV['DB_PASSWORD'] %>
    development:
      dont: touch me
    """
    When I run the shim with argv "--rewrite=config"
    Then the shim should succeed
    And "config/database.yml" should look like:
    """
    integration:
      host: db1.example.com
      user: alibaba
      password: <%= ENV['DB_PASSWORD'] %>
    development:
      dont: touch me
    """

  Scenario: bad key
    Given an app file "config/database.yml" containing:
    """
    integration:
      host: <<app1.bad-key>>
    """
    When I run the shim with argv "--rewrite=config"
    Then the shim should fail
    And the output should include "CMDB: Bad Key: malformed CMDB key 'app1.bad-key'"

  Scenario: bad value
    Given a file source "/var/lib/cmdb/bad.yml" containing:
    """
    value:
      - {a: 1}
    """
    And an app file "config/database.yml" containing:
    """
    integration:
      host: <<bad.value>>
    """
    When I run the shim with argv "--rewrite=config"
    Then the shim should fail
    And the output should include "CMDB: Bad Value: illegal value for CMDB key 'bad.value' in source file:/"

  Scenario: bad data
    Given a file source "/var/lib/cmdb/bad.yml" containing:
    """
    {{{ take THIS, foul YAML parser!
    """
    And an app file "config/database.yml" containing:
    """
    integration:
      host: <<bad.value>>
    """
    When I run the shim with argv "--rewrite=config"
    Then the shim should fail
    And the output should include "CMDB: Bad Data: malformed CMDB data in source file:/"

  Scenario: missing keys
    And an app file "config/missing.yml" containing:
    """
    missing: <<app1.missing>>
    """
    When I run the shim with argv "--rewrite=config"
    Then the shim should fail
    And the output should include "Cannot rewrite configuration"
    And the output should include "app1.missing"

  Scenario: override dir
    Given an app file "config/untouched.yml" containing:
    """
    dont: <<touch.me>>
    """
    And an app file "real_config/database.yml" containing:
    """
    hello: <<app1.database.host>>
    """
    When I run the shim with argv "--rewrite=real_config"
    Then the shim should succeed
    And "config/untouched.yml" should look like:
    """
    dont: <<touch.me>>
    """
    And "real_config/database.yml" should look like:
    """
    hello: db1.example.com
    """
