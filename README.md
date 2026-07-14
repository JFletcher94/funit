[![foundrygg.com](https://img.shields.io/badge/foundrygg-4a1402?style=for-the-badge&logo=vercel&logoColor=white)](https://foundrygg.com) [![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/VuVhYUBbWE) [![Gitlab Pipeline Status](https://img.shields.io/gitlab/pipeline-status/jfletcher94%2Ffunit?branch=master&style=for-the-badge&logo=gitlab)](https://gitlab.com/jfletcher94/funit/-/pipelines)

## [Funit](funit/)

Funit is a unit testing framework for Factorio mods. Factorio is automation game, after all—stop hand-crafting your tests!

You can read my articles on automated testing for Factorio mods at The Foundry:

* [Part 1: Creating Automated Tests](https://www.foundrygg.com/blog/automated-testing-1)
* [Part 2: Running Tests in CI Pipelines](https://www.foundrygg.com/blog/automated-testing-2)

This repo has several features:

* FUnit, a Factorio utility mod for writing unit tests:
    * See the [`funit/`](funit/) directory for documentation on writing tests with FUnit.
    * You can find FUnit on the [mod portal](https://mods.factorio.com/mod/funit).
* Project automation templates:
    * [GitLab CI pipline](.gitlab-ci.yml): automatically build, test and deploy your mod(s) with GitLab CI.
    * [Dockerized Factorio server](Dockerfile): run tests on a headless Factorio server in Docker, thanks to [`factorio-docker`](github.com/factoriotools/factorio-docker/).
    * [Configurable test runner](entrypoint.sh): automatically sync mods and mod settings, and run multiple test suites.
    * (WIP) [GitHub Actions pipeline](.github/workflows/funit.yml): automatically build and test your mod(s) with GitHub Actions (this is a WIP that is less actively maintained, and may not be up to date).
* Helper scripts:
    * [Expand dependencies](scripts/expand_dependencies.rb): Recursively expands mod dependencies.
    * [Parse FUnit json](scripts/parse_funit_json.rb): Parses FUnit's test report json files and saves results to a JUnit-style XML file.

For examples, see:

* [FUnit's own tests](https://gitlab.com/jfletcher94/funit/-/blob/master/funit/scenarios/__funit__test/control.lua)
* [Planet Crucible](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/planet-crucible/scenarios)
* [Rigor Module](https://gitlab.com/jfletcher94/factorio-mods/-/tree/master/rigor-module/scenarios)

### Issues

* See [here](https://github.com/factoriotools/factorio-docker/issues/613).

### License

This project is [licensed](LICENSE) under the **GNU Lesser General Public License v3 or later** ([LGPL-3.0-or-later](https://www.gnu.org/licenses/lgpl+gpl-3.0-standalone.html)), _with the following exception for CI configuration files_:

You can freely copy and distribute CI configuration files with project-specific tweaks, to the extent such changes are required to get CI to work for your project. Such changes, so long as they are project-specific and not general changes/improvements, do not trigger the LGPL copyleft obligation.