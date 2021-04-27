erlchroma
=====

 an  otp erlang library with bindings for the [chromaprint] library.
 
 Chromaprint is an audio fingerprint library developed for the AcoustID project.

 Chromaprint is designed to identify near-identical audio and the fingerprints it generates are as compact as possible to achieve that.

 It's not a general purpose audio fingerprinting solution. It trades precision and robustness for search performance. 

 The target use cases are full audio file identifcation, duplicate audio file detection and long audio stream monitoring.






[chromaprint]: https://github.com/acoustid/chromaprint/

Build
-----

    $ rebar3 compile
