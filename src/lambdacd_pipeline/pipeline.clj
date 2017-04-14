(ns lambdacd-pipeline.pipeline
  (:use [lambdacd.steps.control-flow]
        [lambdacd-pipeline.steps])
  (:require [lambdacd.steps.control-flow :refer [either with-workspace in-parallel run]]
            [lambdacd.steps.manualtrigger :refer [wait-for-manual-trigger]]
            [lambdacd-git.core :as core]))

(def pipeline-structure
  `((either
      wait-for-manual-trigger
      wait-for-git)
     (with-workspace
       clone
       core/list-changes
       (alias "test & check"
         (run
           download-dependencies
           (in-parallel
             test
             check-style
             repeat-unit-tests-to-check-for-flakiness))))))
