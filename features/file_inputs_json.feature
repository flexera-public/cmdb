Feature: CMDB inputs from YAML files
  In order to enhance uptime and productivity
  cmdb should accept static CMDB inputs from files on disk
  So we can store static inputs and audit changes to them

  Background:
    Given an etc file "shard.json" containing:
    """
    {
      "id": 3,
      "name": "lax.example.com",
      "database": {
        "host": "confusing-but-valid-duplicate"
      }
    }
    """

  Scenario: common and app-specific files
    Given an etc file "app1.json" containing:
    """
    {
      "database": {
        "host": "db1.example.com",
        "user": "alibaba",
        "password": "open sesame"
      }
    }
    """
    Then <<app1.database.host>> should be "db1.example.com"
    And <<shard.database.host>> should be "confusing-but-valid-duplicate"
    And <<shard.name>> should be "lax.example.com"

  Scenario: structured and typed data
    Given an etc file "app1.json" containing:
    """
    {
      "admins": [
        "tom",
        "dick",
        "harry"
      ],
      "awesome": true,
      "lucky": 777,
      "sucky": false
    }
    """
    And <<app1.awesome>> should be true
    Then <<app1.admins>> should be ['tom', 'dick', 'harry']
    And <<app1.lucky>> should be 777
    And <<app1.sucky>> should be false

  Scenario: bad data
    Given an etc file "app1.json" containing:
    """
    }}}} eye am nawt valid JSON {{
    """
    Then the code should raise CMDB::BadData

  Scenario: bad value
    Given an etc file "app1.json" containing:
    """
    {
      "admins": [
        {"tom": true},
        [1,2,3,4,5],
        {"harry": true}
      ]
    }
    """
    Then the code should raise CMDB::BadValue
