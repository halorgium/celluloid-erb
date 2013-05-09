celluloid-erb
=============

A demonstration of using Celluloid to build view markup in a parallel without having to modify the template logic. 

* `success.rb` shows an example where there are no timeouts or errors. 
* `error.rb` shows an example where a timeout occurs and aborts the template rendering. 

To run the examples, you'll need to bundle and run. 

```
bundle
bundle exec ruby success.rb
bundle exec ruby error.rb
