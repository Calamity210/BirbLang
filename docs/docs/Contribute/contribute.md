---
id: contributing
title: Contributing
sidebar_label: Contributing
slug: /contributing
---

Want to contribute to birb? This document should help you get started!
## How to contribute?
There are many ways you can contribute:
- Open issues on the [repo](https://github.com/Calamity210/BirbLang) to report bugs or suggest features
- Help fellow developers in our [discord server](https://discord.gg/TkNg8dH)
- Help out with our docs
- Help out with the language directly by opening PRs

## How do I get started
- Clone the repo from https://github.com/Calamity210/BirbLang, be sure to clone the master branch
- Navigate to the new directory and open it in your IDE of choice.
- To work on the docs, open up the `docs/` directory and see the [docs section below](#docs)
- For working on the language itself, look within the `lib/` directory
- To try out your changes, run the following from the root of the birb project:
```shell
$ dart lib/birb.dart
```
- Once you are confident with your changes, make sure you documented everything that is needed and that it follows our style guide.

:::warning
Our style guide is a work in progress, for now please use dartfmt
:::

- All PRs must have added tests to the `examples/` folder, if you think your change should be exempt, let Calamity210#7999 know on discord

:::tip You can generate an executable by running
```shell
$ dart2native lib/Birb.dart
```
:::

- When ready, open and pull request and request a review from any contributor.

## Working on the docs

### Create a new document
To create a new document, add it within the relevant subdirectory within `docs/`.
At the top of the file, type: 
```
---
id: some id // prefer lowercase
title: Some Title // Capitalize first letter
---
```

Open `sidebars.js` and add its id in its respective place.

To test your changes, run:
```shell
$ yarn install
$ yarn start
```

and browse to `http://localhost:3000/` in your browser.
When you are confident with your changes, open a pull request and request a contributor to review it.

### Edit an older document
Find the doc in the `docs/` directory and make your changes.

To test your changes, run: 
```shell
$ yarn install
$ yarn start
```

and browse to `http://localhost:3000/` in your browser.
When you are confident with your changes, open a pull request and request a contributor to review it.

We look forward too your contribution!
