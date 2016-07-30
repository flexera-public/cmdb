@docker
Feature: CMDB inputs from Consul k/v store
  In order to be useful with a wide range of deployment scenarios
  cmdb should support Consul as an input source

  Background:
    Given a consul cluster at consul://consul

  Scenario: top-level read with serialized values
    Given a source "consul://consul#source1"
    And a consul key "/monkeys" with value "apes and gibbons and stuff"
    And a consul key "/numbers" with value "[4,8,15,16,23,42]"
    Then <<source1.monkeys>> should be "apes and gibbons and stuff"
    And <<source1.numbers>> should be [4, 8, 15, 16, 23, 42]