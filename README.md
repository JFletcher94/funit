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