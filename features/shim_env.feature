Feature: env-populating shim for 12-factor apps
  In order to support popular development practices
  cmdb should make CMDB inputs available in the environment
  So it plays nicely with dotenv

  Background:
    Given a trivial app
    And a file source "/var/lib/cmdb/app1.yml" containing:
    """
    database:
      host: db1.example.com
      user: alibaba
      password: open sesame
    """
    And a file source "/var/lib/cmdb/shared.yml" containing:
    """
    favorite:
      color: blue
      music: jazz
    lucky_numbers:
      - 3
      - 7
    age: 7.5
    coffee: true
    """

  Scenario: simple ENV population
    When I run cmdb with "shim env"
    Then the output should have keys: DATABASE_HOST=db1.example.com;FAVORITE_COLOR=blue;LUCKY_NUMBERS=[3,7];AGE=7.5;COFFEE=true

  Scenario: naming conflict
    Given a file source "/var/lib/cmdb/interloper.yml" containing:
    """
    favorite:
      music: hip hop
    """
    When I run cmdb with "shim env"
    Then the command should fail
    And the output should include "CMDB: Name Conflict: FAVORITE_MUSIC corresponds to 2 different keys"

  Scenario: conflict with existing ENV keys
    Given $FAVORITE_MUSIC is "rock & roll"
    When I run cmdb with "shim env"
    Then the command should fail
    And the output should include "CMDB: Environment Conflict: FAVORITE_MUSIC is already present in the environment; cannot override with CMDB values"
