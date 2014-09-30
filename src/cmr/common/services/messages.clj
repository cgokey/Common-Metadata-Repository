(ns cmr.common.services.messages
  "This namespace provides functions to generate messages used for error reporting, logging, etc.
  Messages used in more than one project should be placed here."
  (:require [clojure.string :as str]
            [cmr.common.services.errors :as errors]
            [camel-snake-kebab :as csk]))

(defn data-error [error-type msg-fn & args]
  "Utility method that uses throw-service-error to generate a response with a specific status code
  and error message."
  (errors/throw-service-error error-type (apply msg-fn args)))

(defn invalid-msg
  "Creates a message saying that value does not conform to type."
  ([type value]
   (invalid-msg type value nil))
  ([type value context]
   (let [type-name (if (keyword? type)
                     (name type)
                     (str type))
         context-str (if context
                       (str " : " context)
                       "")]
     (format "[%s] is not a valid %s%s" (str value) type-name context-str))))

(defn invalid-numeric-range-msg
  "Creates a message saying the range string does not have the right format."
  [input-str]
  (format (str "[%s] is not of the form 'value', 'min-value,max-value', 'min-value,', or ',max-value'"
               " where value, min-value, and max-value are optional numeric values.")
          input-str))

(defn invalid-date-range-msg
  "Creates a message saying the range string does not have the right format."
  [input-str]
  (format (str "[%s] is not of the form 'value', 'min-value,max-value', 'min-value,', or ',max-value'"
               " where value, min-value, and max-value are optional date-time values.")
          input-str))

(defn invalid-ignore-case-opt-setting-msg
  "Creates a message saying which parameters would not allow ignore case option setting."
  [params-set]
  (let [params (reduce (fn [params param] (conj params param)) '() (seq params-set))]
    (format "Ignore case option setting disallowed on these parameters: %s" params)))

(defn invalid-pattern-opt-setting-msg
  "Creates a message saying which parameters would not allow pattern option setting."
  [params-set]
  (let [params (reduce (fn [params param] (conj params param)) '() (seq params-set))]
    (format "Pattern option setting disallowed on these parameters: %s" params)))

(defn invalid-exclude-param-msg
  "Creates a message saying supplied parameter(s) are not in exclude params set."
  [params-set]
  (format "Parameter(s) [%s] can not be used with exclude." (str/join ", " (map name params-set))))

(defn invalid-or-opt-setting-msg
  "Creates a message saying which parameter is not allowed to use the 'or' option."
  [param]
  (format "'or' option is not valid for parameter [%s]" param))

(defn invalid-opt-for-param
  "Creates a message saying supplied option is not allowed for parameter."
  [param option]
  (str "Option [" (csk/->snake_case_string option)
       "] is not supported for param [" (csk/->snake_case_string param) "]"))