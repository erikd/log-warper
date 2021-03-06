log-warper
==========

[![Build Status](https://travis-ci.org/serokell/log-warper.svg)](https://travis-ci.org/serokell/log-warper)
[![Hackage](https://img.shields.io/hackage/v/log-warper.svg)](https://hackage.haskell.org/package/log-warper)
[![Stackage LTS](http://stackage.org/package/log-warper/badge/lts)](http://stackage.org/lts/package/log-warper)
[![Stackage Nightly](http://stackage.org/package/log-warper/badge/nightly)](http://stackage.org/nightly/package/log-warper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Auxilary logging library, which is wrapper over
[hslogger](http://hackage.haskell.org/package/hslogger) but allows
to keep logger name into monadic context, making logging less boilerplate.

Key features:

1. Output is colored :star:
2. Supports logging initialization from `.yaml` configuration file
3. Has wrapper for pure logging via `StateT`
4. Supports log rotation
5. Flexibles and easy setting up of loggers (using monoidal builders and lenses)
6. Ability to acquire last `N` megabytes of logs from in-memory cache

Contributing
------------

> **This project uses [`universum`](https://github.com/serokell/universum)
> as default prelude**
