
;# Initialization - load function handler
;source $LAMBDA_TASK_ROOT/"$(echo $_HANDLER | cut -d. -f1).sh"
;
;# Processing
;while true
;do
;  HEADERS="$(mktemp)"
;  # Get an event
;  EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
;  REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)
;
;  # Execute the handler function from the script
;  RESPONSE=$($(echo "$_HANDLER" | cut -d. -f2) "$EVENT_DATA")
;
;  # Send the response
;  curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response"  -d "$RESPONSE"
;done
(ns bootstrap
  (:require [joker.walk :as walk]
            [joker.json :as json]
            [joker.os :as os]
            [joker.http :as http]))

(defn invocation-url [env]
  (str "http://"
       (:AWS_LAMBDA_RUNTIME_API env)
       "/2018-06-01/runtime/invocation/next"))

(defn response-url [env request-id]
  (str "http://"
       (:AWS_LAMBDA_RUNTIME_API env)
       "/2018-06-01/runtime/invocation/"
       request-id
       "next"))

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

(defn send-response [env request-id response]
  (http/send {:url (response-url env request-id)
              :method :post
              :body response}))

(defn process-event [env]
  (let [event (next-event env)
        request-id (-> event :headers :Lambda-Runtime-Aws-Request-Id)]
    (println event)
    (send-response env request-id "ok")))

(defn main []
  (println "Bootstrapping system ...")
  (let [env (-> (os/env)
                (walk/keywordize-keys))]
    (println "Bootstrap env:")
    (pprint env)
    (println "Start process loop ...")
    (while true
      (process-event env))))

(main)
