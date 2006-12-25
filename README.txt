= rc-rest

Rubyforge Project:

http://rubyforge.org/projects/rctools/

Documentation:

http://dev.robotcoop.com/Libraries/rc-rest/

== About

This is an abstract class for creating wrappers for REST web service APIs.

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

