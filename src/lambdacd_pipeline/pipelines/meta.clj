(ns lambdacd-pipeline.pipelines.meta
  (:require [lambdacd.steps.control-flow :refer [either with-workspace in-parallel run alias]]
            [lambdacd.steps.manualtrigger :refer [wait-for-manual-trigger]]
            [lambdacd-git.core :as core]
            [lambdacd.steps.shell :as shell]))

(defn dummy [args ctx]
  (shell/bash ctx "/"
              "echo hello"))

(def pipeline-structure
  `((either
      wait-for-manual-trigger)
     dummy))
