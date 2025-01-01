# Testing Strategy for Microservice in cloud

As we started the journey to the cloud, we had to move away from the waterfall or V-process model of development.
We had to approach testing from a new mindset and stratergy. We came up with the below template/structure to get a cleaner and simpler approach.

|Test Approach | Owner | Artifact | Pipeline | Notes |
|----|----|----|----|----|
|**Unit Testing** | | | | Unit tests determine whether they produce the desired output given a set of known inputs.|
|| Dev | Unit Test cases | CI |  Create UT’s using Methods and Interface Mocks |
|||||Use pytest framework|
|||||Code Coverage using UT (coverage.py)|
|||||UT Result should be 100% pass|
|||||Pipeline Acceptance: 100% UT pass with >70% code coverage, no lint errors|



|Test Approach | Owner | Artifact | Pipeline | Notes |
|----|----|----|----|----|
|**Contract Testing** (Consumer) | | | | Unit tests determine whether they produce the desired output given a set of known inputs.|
|| Dev | PACT File | Manual |  Create test cases, involvement from developer and test automation engineer |


|Test Approach | Owner | Artifact | Pipeline | Notes |
|----|----|----|----|----|
|**Contract Testing** (Provider) | | | | Contract testing is a methodology for ensuring that two separate systems (such as two microservices) are compatible with one other.|
|| Dev | PACT File | Manual |  Create test cases, involvement from developer and test automation engineer |

