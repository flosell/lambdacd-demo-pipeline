(ns lambdacd-pipeline.steps
  (:require [lambdacd.steps.shell :as shell]
            [lambdacd-git.core :as core]))

(def repo "https://github.com/flosell/lambdacd.git")

(defn wait-for-git [args ctx]
  (core/wait-for-git ctx repo
                     :ref "refs/heads/master"
                     :ms-between-polls (* 60 1000)))

(defn clone [args ctx]
  (core/clone ctx repo (:revision args) (:cwd args)))

(defn test [args ctx]
  (shell/bash ctx (:cwd args)
              "./scripts/travis_prebuild.sh"
              "./go test"))

(defn download-dependencies [args ctx]
  (shell/bash ctx (:cwd args) "lein deps"))

(defn check-style [args ctx]
  (shell/bash ctx (:cwd args) "./go check-style"))

(defn repeat-unit-tests-to-check-for-flakiness [args ctx]
  (shell/bash ctx (:cwd args) "./go test-clj-unit-repeat"))


