= rc-rest

* http://seattlerb.rubyforge.org/rc-rest
* http://rubyforge.org/projects/rctools/

== DESCRIPTION:

Robot Co-op REST web services base class. This library makes it easy to
implement REST-like web services APIs.

== Installing rc-rest

Just install the gem:

  $ sudo gem install rc-rest

== Using rc-rest

rc-rest is used by gems such as yahoo-search, google-geocode and geocoder-us.
If you'd like to write bindings a web service using rc-rest see RCRest, its
tests or the above-mentioned gems for examples.

== Upgrading from 1.x

RCRest#get and RCRest#make_url now accept a method argument as the
first parameter.  To use 2.x, pass the last component of the path to
RCRest#get or RCRest#make_url.

== Upgrading from 2.x

RCRest now uses Nokogiri instead of REXML.

