(ns bootstrap
  (:require [joker.filepath :as filepath]
            [joker.http :as http]
            [joker.json :as json]
            [joker.os :as os]
            [joker.string :as string]
            [joker.walk :as walk]))

(defn invocation-url [env]
  (str "http://"
       (:AWS_LAMBDA_RUNTIME_API env)
       "/2018-06-01/runtime/invocation/next"))

(defn response-url [env request-id]
  (str "http://"
       (:AWS_LAMBDA_RUNTIME_API env)
       "/2018-06-01/runtime/invocation/"
       request-id
       "/response"))

(defn next-event [env]
  (let [result (http/send {:url (invocation-url env)})
        body (-> result
                 :body
                 (json/read-string)
                 (walk/keywordize-keys))
        headers (-> result
                    :headers
                    (walk/keywordize-keys))]
    {:body body
     :headers headers}))

(defn send-response [env event response]
  (let [request-id (-> event :headers :Lambda-Runtime-Aws-Request-Id)]
    (http/send {:url (response-url env request-id)
                :method :post
                :body response})))

(defn process-event [env handler]
  (let [event (next-event env)
        response (handler env event)]
    (send-response env event response)))

(defn load-handler [env]
  (let [[handler-file handler-name] (string/split (:_HANDLER env) #"/")]
    (load-file (filepath/join (:LAMBDA_TASK_ROOT env) (str handler-file)))
    (resolve (symbol handler-name))))

(defn main []
  (let [env (-> (os/env)
                (walk/keywordize-keys))]
    (println "Bootstrap env:")
    (pprint env)
    (println "Loading handler ...")
    (let [handler (load-handler env)]
      (println "Start process loop ...")
      (while true
        (process-event env handler)))))

(main)
