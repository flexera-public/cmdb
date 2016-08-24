Feature: shim CLI validation
  In order to save precious developer time
  The CMDB shim should perform sanity checks of its CLI parameters
  So developers don't get confused

  Background:
    Given a trivial app

  Scenario: complain with no dir, env or command
    When I run cmdb with "shim"
    Then the command should fail
    Then the output should include "nothing to do"

  Scenario: succeed with pretend
    When I run cmdb with "shim --rewrite=. --pretend"
    Then the command should succeed

  Scenario: succeed with just a command
    When I run cmdb with "shim -- bash -c 'echo hello cucumber'"
    Then the command should succeed
    Then the output should include "hello cucumber"
