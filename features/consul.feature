@docker
Feature: Consul k/v store
  In order to be useful with a wide range of deployment scenarios
  cmdb should integrate with popular k/v stores

  Background:
    Given a consul cluster at consul://consul

  Scenario: no namespace
    Given a source "consul://consul"
    And a consul key "/monkeys" with value "apes and gibbons and stuff"
    And a consul key "/numbers" with value "[4,8,15,16,23,42]"
    And a consul key "/nested/goodness" with value "chocolatey"
    And a consul key "/nested/hidden/awesomeness" with value "true"
    Then <<monkeys>> should be "apes and gibbons and stuff"
    And <<numbers>> should be [4, 8, 15, 16, 23, 42]
    And <<nested.goodness>> should be "chocolatey"
    And <<nested.hidden.awesomeness>> should be true

  Scenario: first-level namespace
    Given a source "consul://consul/staging"
    And a consul key "/staging/monkeys" with value "apes and gibbons and stuff"
    And a consul key "/staging/numbers" with value "[4,8,15,16,23,42]"
    Then <<staging.monkeys>> should be "apes and gibbons and stuff"
    And <<staging.numbers>> should be [4, 8, 15, 16, 23, 42]

  Scenario: nested namespace
    Given a source "consul://consul/staging/nyc"
    And a consul key "/staging/nyc/monkeys" with value "apes and gibbons and stuff"
    And a consul key "/staging/nyc/numbers" with value "[4,8,15,16,23,42]"
    Then <<nyc.monkeys>> should be "apes and gibbons and stuff"
    And <<nyc.numbers>> should be [4, 8, 15, 16, 23, 42]
