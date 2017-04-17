(ns lambdacd-pipeline.core
  (:require
    [lambdacd-pipeline.pipelines.lambdacd :as lambdacd-pipeline]
    [lambdacd-pipeline.pipelines.meta :as meta-pipeline]
    [lambdacd-pipeline.ui-selection :as ui-selection]
    [org.httpkit.server :as http-kit]
    [lambdacd.runners :as runners]
    [lambdacd.util :as util]
    [lambdacd.core :as lambdacd]
    [clojure.tools.logging :as log]
    [hiccup.core :as h]
    [compojure.core :as compojure])
  (:gen-class))

(def pipeline-configs [{:name               "LambdaCD Pipeline"
                        :pipeline-url       "/lambdacd"
                        :pipeline-structure lambdacd-pipeline/pipeline-structure}
                       {:name               "Meta Pipeline"
                        :pipeline-url       "/meta"
                        :pipeline-structure meta-pipeline/pipeline-structure}])

(defn pipeline-for [pipeline-config]
  (let [home-dir           (util/create-temp-dir)
        config             {:home-dir home-dir :name (:name pipeline-config)}
        pipeline-structure (:pipeline-structure pipeline-config)
        pipeline           (lambdacd/assemble-pipeline pipeline-structure config)
        app                (ui-selection/ui-routes pipeline (:pipeline-url pipeline-config))]
    (runners/start-one-run-after-another pipeline)
    app))

(defn mk-context [project]
  (let [app (pipeline-for project)]
    (compojure/context (:pipeline-url project) [] app)))

(defn mk-link [{url :pipeline-url name :name}]
  [:li
   name
   [:ul
    [:li [:a {:href (str url "/reference/")} "Reference UI"]]
    [:li [:a {:href (str url "/lambdaui/lambdaui/index.html")} "LambdaUI"]]]])

(defn mk-index [projects]
  (h/html
    [:html
     [:head
      [:title "Pipelines"]]
     [:body
      [:h1 "Pipelines:"]
      [:ul (map mk-link projects)]]]))

(defn -main [& args]
  (let [contexts (map mk-context pipeline-configs)
        routes   (apply compojure/routes
                        (conj contexts (compojure/GET "/" [] (mk-index pipeline-configs))))]
    (http-kit/run-server routes {:open-browser? false
                                 :port          8080})))
