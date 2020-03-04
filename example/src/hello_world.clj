(ns hello-world
  (:require [joker.json :as json]))

(defn handle [env event]
  (let [body (-> event :body)]
    (println "Got request: " body)
    (json/write-string {:hello "world"})))
