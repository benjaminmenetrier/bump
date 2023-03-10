[![travis develop](https://travis-ci.com/JCSDA/saber.svg?token=zswWHqwVimHTBAygfenZ&branch=develop&logo=travis)](https://travis-ci.com/JCSDA/saber)
[![codecov](https://codecov.io/gh/JCSDA/saber/branch/develop/graph/badge.svg?token=aLmdMnzx1C)](https://codecov.io/gh/JCSDA/saber)
GNU: [![AWS-gnu](https://codebuild.us-east-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiV2dVMmxFVENKL2dCVzN5UlgyZHJuSmhvbTV6dDhOalYwTEJDaXdZWGFDbXp2YlU4VzdsV3ZRNm9mT25mRnM3NlVYWXE2R2pmYVlZbWhxbHJ1OXFpdzVjPSIsIml2UGFyYW1ldGVyU3BlYyI6Ilp2T04vNnBRR0xFYmQ3UzAiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=develop)](https://us-east-1.console.aws.amazon.com/codesuite/codebuild/projects/automated-testing-saber-gnu/history)
INTEL: [![AWS-intel](https://codebuild.us-east-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiYUROTE5DZVdranpBQTBKbTlBam1vb2pVWXJteDdEMk1RLzhWdmlQU2NUQUhueFF2UnhINWxDcGZ1eWFqcFpBUVRDMGpYdVhzSWdmazNYcmRDeUdOd0xRPSIsIml2UGFyYW1ldGVyU3BlYyI6IjhqZnUxOHpObWFGSnFtUzYiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=develop)](https://us-east-1.console.aws.amazon.com/codesuite/codebuild/projects/automated-testing-saber-intel/history?region=us-east-1)
CLANG: [![AWS-Clang](https://codebuild.us-east-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiL3NrZ05zdXQzbmlhOTJOT0RVanBwKzhocXhIb0tpdnFFMzAzdjd6RmN4V0FpRTJMVkdYcGJoVS9CTlE0L3dXS3JvclZxZU12U0lVWjdBb3krZ2xzODBBPSIsIml2UGFyYW1ldGVyU3BlYyI6IklHcGQ0VUJNOWdzNHNyWE0iLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=develop)](https://us-east-1.console.aws.amazon.com/codesuite/codebuild/projects/automated-testing-saber-clang/history?region=us-east-1)

# SABER
&copy; Copyright 2019 UCAR

This software is licensed under the terms of the Apache Licence Version 2.0
which can be obtained at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0).

Details about the repository can be found in the [overview of the SABER code](doc/overview.md).

## BUMP

The BUMP (B matrix on an Unstructured Mesh Package) library estimates and applies background error covariance-related operators, defined on an unstructured mesh.

### Licensing
Most of the BUMP code is distributed under the [CeCILL-C license](http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html) (Copyright ?? 2015-... UCAR, CERFACS, METEO-FRANCE and IRIT).

The fact that you are downloading this code means that you have had knowledge of the [CeCILL-C license](http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html) and that you accept its terms.

### Theoretical documentation
 - about covariance filtering: [covariance_filtering.pdf](https://github.com/benjaminmenetrier/covariance_filtering/blob/master/covariance_filtering.pdf)
 - about the NICAS method: TO BE DONE
 - about multivariate localization: [multivariate_localization.pdf](https://github.com/benjaminmenetrier/multivariate_localization/blob/master/multivariate_localization.pdf)
 - about diffusion and the Matern function: TO BE DONE

### Code documentation
 - [Standalone or online usage](doc/bump/standalone_or_online_usage.md)
 - [Input data](doc/bump/input_data.md)
 - [Running the code](doc/bump/running_the_code.md)
 - [Test](doc/bump/test.md)
 - [Adding a new model](doc/bump/adding_a_new_model.md)

## Other libraries coming soon ...
