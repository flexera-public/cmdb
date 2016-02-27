Feature: hierarchy of CMDB input file locations
  In order to facilitate CMDB usage in test, development and deployment
  cmdb should look for input files in several different locations
  So apps provide defaults, developers provide local overrides, and Ops provides deploy-time values

  Background:
    Given a working-dir file "app1.json" containing:
    """
    {"alas": "friends"}
    """

  Scenario: default to working-dir in development
    Given RACK_ENV is "development"
    Then <<app1.hello>> should be nil
    And <<app1.goodbye>> should be nil
    And <<app1.alas>> should be "friends"

  Scenario: default to homedir in production
    Given RACK_ENV is "production"
    And a homedir file "app1.json" containing:
    """
    {"goodbye": "world"}
    """
    Then <<app1.hello>> should be nil
    And <<app1.goodbye>> should be "world"
    And <<app1.alas>> should be nil

  Scenario: homedir overrides working-dir in development
    Given RACK_ENV is "development"
    And a homedir file "app1.json" containing:
    """
    {"goodbye": "world"}
    """
    Then <<app1.hello>> should be nil
    And <<app1.goodbye>> should be "world"
    And <<app1.alas>> should be nil

  Scenario: etc overrides working-dir in production
    Given RACK_ENV is "production"
    And an etc file "app1.json" containing:
    """
    {"hello": "world"}
    """
    Then <<app1.hello>> should be "world"
    And <<app1.goodbye>> should be nil
    And <<app1.alas>> should be nil
