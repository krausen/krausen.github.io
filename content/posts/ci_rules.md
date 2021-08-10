---
title: "Simple rules for CI"
date: 2021-08-08T15:02:58+02:00
draft: false
---
#### Don't branch (or at least keep them short lived)
The goal of Continuous Integration is to integrate often. Long lived branches work against this goal and should be avoided. As a rule of thumb you should strive to at least have you changes pushed to the remote master before the end of your work day.
#### Have a fast test suite
Have a lightning fast test suite, a couple of minutes at the most. The CI is there to help you and your team to stay efficient, no one has the time to wait around for a slow test suite. Fail fast, if a single test case fails it should be enough fail the entire test suite. If you have different types of tests (Unit, component, system etc) run the fastest first. We want feedback as fast as possible!
#### The committer is responsible to fix failed builds
The committer of the broken code is responsible to fix it. If you know right away how to fix it just go ahead and do it. If you need to troubleshoot further then revert the change so that you do not stand in the way of your team mates. As a guideline a fix or revert should be in place within 10 minutes so that you are not blocking your team mates. You should also work proactively by running the tests locally first.
#### Every commit should run on a build machine
The goal of every commit is to add value to the product and help you customers. The harsh reality is that until your code runs in production it is practically useless. Ideally the build should run on a machine that is as similar to the production environment as possible. This will give increase the probability that it will work in production. Most likely your dev machine deviate a bit from the production environment. It is also possible that some changes works on your machine and not on your colleagues. Let the central build machine be the decider on what is the most correct environment and test result.