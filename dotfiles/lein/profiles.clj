{:user {:plugins [[lein-cljsbuild "1.0.1"]
                  [lein-clojars "0.9.1"]
                  [lein-midje    "3.1.3"]
                  [lein-midje-doc "0.0.18"]
                  [codox "0.6.6"]]
        :dependencies [[spyscope "0.1.4"]
                       [org.clojure/tools.namespace "0.2.4"]
                       [io.aviso/pretty "0.1.8"]
                       [im.chit/vinyasa "0.1.8"]]
        :injections [(require 'spyscope.core)
                     (require 'vinyasa.inject)

                     (vinyasa.inject/inject
                       'clojure.core
                       '[[vinyasa.inject [inject inject]]
                         [vinyasa.pull [pull pull]]
                         [vinyasa.lein [lein lein]]
                         [clojure.repl apropos dir doc find-doc source
                          [root-cause cause]]
                         [clojure.tools.namespace.repl [refresh refresh]]
                         [clojure.pprint [pprint >pprint]]
                         [io.aviso.binary [write-binary >bin]]])

                      (require 'io.aviso.repl
                               'clojure.repl
                               'clojure.main)
                      (alter-var-root #'clojure.main/repl-caught
                        (constantly @#'io.aviso.repl/pretty-pst))
                      (alter-var-root #'clojure.repl/pst
                        (constantly @#'io.aviso.repl/pretty-pst))
                     ]
        }}
