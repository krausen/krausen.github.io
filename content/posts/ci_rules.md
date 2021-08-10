---
title: "Simple rules for CI"
date: 2021-08-08T15:02:58+02:00
draft: false
---

I like the concept of [Simple rules](https://www.youtube.com/watch?v=BgD3V-IyVT4). Basically they are 3-5 simple rules on how to deal with a complex problem.
This is not magic number but keeping it in that range makes them easy to remember and the constraint forces you to think about the essential and most important rules. They should be followed as a guideline when making decisions rather than followed as an algorithm. In my experience they work well in sticking to a strategy or way of working in a team. Keep them explicitly written down and update them when you learn better ways of dealing with the problem. To demonstrate this I decided share my simple rules for Continuous Integration.


#### Don't branch (or at least keep them short lived)
The goal of CI is to integrate often. Long lived branches work against this goal and should be avoided. As a rule of thumb you should strive to at least have you changes on the remote master before the end of your work day.
#### Have a fast test suite
Have a lightning fast test suite, a couple of minutes at the most. The CI is there to help you and your team to stay efficient, no one has the time to wait around for a slow test suite. Fail fast, if a single test case fails it should be enough fail the entire test suite. If you have different types of tests (Unit, component, system etc) run the fastest first. We want feedback as fast as possible!
#### The committer is responsible to fix failed builds
The committer of the broken code is responsible to fix it. If you know right away how to fix it just go ahead and do it. If you need to troubleshoot further then revert the change so that you do not stand in the way of your team mates. As a guideline a fix or revert should be in place within 10 minutes so that you are not blocking your team mates. You should also work proactively by running the tests locally first.
#### Every commit should run on a build machine
The goal of every commit is to add value to the product and help you customers. The harsh reality is that until your code runs in production it is practically useless. Ideally the build should run on a machine that is as similar to the production environment as possible. This will give increase the probability that it will work in production. Most likely your dev machine deviate a bit from the production environment. It is also possible that some changes works on your machine and not on your colleagues. Let the central build machine be the decider on what is the most correct environment and test result.