Feature: promote subkeys to root
  In order to support complex deployment scenarios
  cmdb should promote subkeys with a specific name the root of a namespace
  So a given k/v store can contain several different profiles for an application

  Background:
    Given a trivial app
    And an etc file "flat.json" containing:
    """
    {
     "scrumptious": true
    }
    """

    Given an etc file "subkeys.json" containing:
    """
    {
     "not_my_circus": "not_my_monkey",
     "development": {"chewy": true},
     "staging": {"chewy": false}
    }
    """

  Scenario: tolerate missing subkey
    When I run the shim with argv "--env --root=staging env"
    Then the shim should succeed
    And the output should include "SCRUMPTIOUS=true"

  Scenario: specialize for staging
    When I run the shim with argv "--env --root=staging env"
    Then the shim should succeed
    And the output should include "CHEWY=false"
    And the output should not include "NOT_MY_CIRCUS"
