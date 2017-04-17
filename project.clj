(defproject lambdacd-pipeline "0.1.0-SNAPSHOT"
            :description "Complete, deployable LambdaCD demo project with AWS infrastructure"
            :url "http://github.com/flosell/lambdacd-demo-pipeline"
            :license {:name "Apache License, version 2.0"
                      :url "http://www.apache.org/licenses/LICENSE-2.0.html"}
            :dependencies [[lambdacd "0.13.1"]
                           [lambdacd-git "0.2.0"]
                           [lambdaui "0.4.0"]
                           [http-kit "2.2.0"]
                           [org.clojure/clojure "1.7.0"]
                           [org.clojure/tools.logging "0.3.1"]
                           [org.slf4j/slf4j-api "1.7.5"]
                           [ch.qos.logback/logback-core "1.0.13"]
                           [ch.qos.logback/logback-classic "1.0.13"]]
            :profiles {:uberjar {:aot :all}}
            :main lambdacd-pipeline.core)
