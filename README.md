# rack-objectspace
[![Build Status](https://travis-ci.org/iainbeeston/rack-objectspace.svg)](https://travis-ci.org/iainbeeston/rack-objectspace)

This is my attempt to make a rack middleware that profiles memory usage in rails (or any rack-based app), with the aim of detecting memory leaks. After *every* request it takes a dump of the objectspace and saves it to a data store of your choice\*.

\* Any object supporting the `[]=` method can be used as a data-store. I recommend [Moneta](http://github.com/minad/moneta), which has support for Redis and Amazon S3.

## Getting Started

After installing the gem, insert rack-objectspace into your middleware stack:

~~~
config.middleware.insert_after ActionDispatch::Static, Rack::Objectspace, store: Moneta.new(:Redis)
~~~

I'd recommend installing rack-objectspace as low as you can in your stack. Preferably only requests that hit your own application code should be profiled.

## Warnings

* **DO NOT USE THIS IN PRODUCTION** (it's *VERY* slow - I'd recommend running it on a close-copy of production instead)
* It relies on MRI ruby's ObjectSpace. This won't work in MRI Ruby < 2.1, or any version of JRuby or Rubinius.
* Every objectspace dump is unique to a particular ruby process. Make sure your server is only running a single worker when profiling.
* I've found that with unicorn, requests will usually time-out when using rack-objectspace. Try increasing the `timeout` value in unicorn.rb.

## How to find memory leaks

Right now this bit is manual. rack-objectspace will give you the objectspace for a running app. I'd recommend taking the objectspace dumps for several successive requests and looking for objects that aren't garbage collected, as @wagenet did in his [post on the Skylight blog](http://blog.skylight.io/hunting-for-leaks-in-ruby/).

## Credits

This project was heavily inspired by blog posts by [@samsaffron](http://samsaffron.com/archive/2015/03/31/debugging-memory-leaks-in-ruby) and [@wagenet](http://blog.skylight.io/hunting-for-leaks-in-ruby/). I take no credit for the technique used here.

Also, many thanks to [@newbamboo](https://www.new-bamboo.co.uk) for letting me work on this during office hours.
