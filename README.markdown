#Ruby TextMate Bundle

##Description

####Changes
 * Updated to allow running of shoulda tests
 * Fixed links of broken tests so they properly link to each line of failing test's backtrace
 * Cleaned up output of running tests
 * Updated toggle quotes command to use ! as the delimiter instead of {} since {} is used by ruby interpolation
 * Lots of new snippets and commands:
   * <code>⌃⇧+/</code> Toggle try or not (ie cow.moo <-> cow.try(:moo))
   * <code>⌃+H</code> Replaces escaped characters in plain text files (sometimes ruby outputs \n \" etc)
   * Clean up and addition of lots of new snippets

##Installation

1. $ `cd ~/Library/Application\ Support/TextMate/Bundles/`
2. $ `git clone git://github.com/phuibonhoa/ruby-tmbundle.git Ruby.tmbundle`
3. $ `osascript -e 'tell app "TextMate" to reload bundles'`

If you'd like to install all my bundles, check out this [script](http://gist.github.com/443129) written by [mkdynamic](http://github.com/mkdynamic).  It installs all bundles and backups any existing bundles with conflicting names.  Thanks Mark!

###Using [Spork](https://github.com/timcharper/spork) with focus tests:
* gem install spork --pre (requires spork-0.9.rc9)
* open TextMate preferences and set environment variable SPORK_TESTUNIT=true
* initialize your app for spork (see spork README)
* open a terminal window, cd to the root of your rails app and run spork command.
* focus tests will be run through spork.

##My Other Textmate Bundles
My bundles work best when use in conjunction with my other bundles:

 * Rails - [http://github.com/phuibonhoa/ruby-on-rails-tmbundle](http://github.com/phuibonhoa/ruby-on-rails-tmbundle)
 * Ruby - [http://github.com/phuibonhoa/ruby-tmbundle](http://github.com/phuibonhoa/ruby-tmbundle)
 * Shoulda - [http://github.com/phuibonhoa/ruby-shoulda-tmbundle](http://github.com/phuibonhoa/ruby-shoulda-tmbundle)
 * HAML - [http://github.com/phuibonhoa/handcrafted-haml-textmate-bundle](http://github.com/phuibonhoa/handcrafted-haml-textmate-bundle)
 * Sass - [http://github.com/phuibonhoa/ruby-sass-tmbundle](http://github.com/phuibonhoa/ruby-sass-tmbundle)
 * JavaScript - [http://github.com/phuibonhoa/Javascript-Bundle-Extension](http://github.com/phuibonhoa/Javascript-Bundle-Extension)
 * CTags - [http://github.com/phuibonhoa/tm-ctags-tmbundle](http://github.com/phuibonhoa/tm-ctags-tmbundle)

##Credits

![BookRenter.com Logo](http://assets0.bookrenter.com/images/header/bookrenter_logo.gif "BookRenter.com")

Additions by [Philippe Huibonhoa](http://github.com/phuibonhoa) and funded by [BookRenter.com](http://www.bookrenter.com "BookRenter.com").


Original bundle can be found [here](http://github.com/drnic/ruby-tmbundle)