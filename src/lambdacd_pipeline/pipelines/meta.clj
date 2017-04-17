(ns lambdacd-pipeline.pipelines.meta
  (:require [lambdacd.steps.control-flow :refer [either with-workspace in-parallel run alias]]
            [lambdacd.steps.manualtrigger :refer [wait-for-manual-trigger]]
            [lambdacd.stepsupport.output :as output]
            [lambdacd-git.core :as core]
            [lambdacd.steps.shell :as shell]))

(def repo "https://github.com/flosell/lambdacd-demo-pipeline.git")

(defn wait-for-git [args ctx]
  (core/wait-for-git ctx repo
                     :ref "refs/heads/master"
                     :ms-between-polls (* 60 1000)))

(defn copy-dir [ctx from to]
  (shell/bash ctx "/"
              "echo \"Detected dev-mode. Instead of cloning, copying project from given directory\""
              (str "cp -v -R " from "/* " to)))

(defn clone [args ctx]
  (let [pipeline-project-location (System/getenv "DEV_PIPELINE_PROJECT_LOCATION")]
    (if pipeline-project-location
      (copy-dir ctx pipeline-project-location (:cwd args))
      (core/clone ctx repo (:revision args) (:cwd args)))))


(defn build [args ctx]
  (shell/bash ctx (:cwd args)
              "./go build"))

(defn deploy [args ctx]
  (shell/bash ctx (:cwd args)
              "DEV_MODE=TRUE ./go run-container"
              "./go stop-old-container"))

(def pipeline-structure
  `((either
      wait-for-manual-trigger
      wait-for-git)
     (with-workspace
       clone
       build
       deploy)))
