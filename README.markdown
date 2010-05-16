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
2. $ `git clone git://github.com/handcrafted/handcrafted-haml-textmate-bundle.git Haml.tmbundle`
3. $ `osascript -e 'tell app "TextMate" to reload bundles'`
 
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

Additions by [Philippe Huibonhoa](http://github.com/phuibonhoa)


Original bundle can be found [here](http://github.com/drnic/ruby-tmbundle)