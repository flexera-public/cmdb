Feature: shim CLI validation
  In order to save precious developer time
  The CMDB shim should perform sanity checks of its CLI parameters
  So developers don't get confused

  Background:
    Given a trivial app

  Scenario: complain with no dir, env or command
    When I run the shim with argv ""
    Then the shim should fail
    Then the output should include "nothing to do"

  Scenario: succeed with pretend
    When I run the shim with argv "--dir=. --pretend"
    Then the shim should succeed

  Scenario: succeed with just a command
    When I run the shim with argv "-- bash -c 'echo hello cucumber'"
    Then the shim should succeed
    Then the output should include "hello cucumber"
