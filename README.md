[![foundrygg.com](https://img.shields.io/badge/foundrygg-4a1402?style=for-the-badge&logo=vercel&logoColor=white)](https://foundrygg.com) [![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/VuVhYUBbWE) [![Gitlab Pipeline Status](https://img.shields.io/gitlab/pipeline-status/jfletcher94%2Ffunit?branch=master&style=for-the-badge&logo=gitlab)](https://gitlab.com/jfletcher94/funit/-/pipelines)

## [Funit](funit/)

Funit is a unit testing framework for Factorio mods. Factorio is automation game, after all—stop hand-crafting your mods!

This repo has several features:

* [Funit](funit/): a Factorio utility [mod](https://mods.factorio.com/mod/funit) for writing unit tests
* Project automation templates:
    * [CI pipline](.gitlab-ci.yml): automatically build, test and (mostly) deploy your mod(s) with GitLab CI
    * [Dockerized Factorio server](Dockerfile): run tests on a headless Factorio server (thank you, [factorio-docker](github.com/factoriotools/factorio-docker/)!)
    * [Configurable test runner](entrypoint.sh): automatically sync mods and mod settings, and run multiple test suites
    * [Test reports](scripts/parse_funit_log.rb): generate JUnit-style test reports
    * More to come!

_Documentation is a work in progress!_

See [here](https://gitlab.com/jfletcher94/factorio-mods) for a repo with mods that use FUnit.