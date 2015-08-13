(ns cmr.umm-spec.xml-to-umm-mappings.dif10
  "Defines mappings from DIF10 XML into UMM records"
  (:require [cmr.umm-spec.xml-to-umm-mappings.dsl :refer :all]
            [cmr.umm-spec.xml-to-umm-mappings.add-parse-type :as apt]
            [cmr.umm-spec.json-schema :as js]))

(def dif10-xml-to-umm-c
  (apt/add-parsing-types
    js/umm-c-schema
    (object
      {:EntryTitle (xpath "/DIF/Entry_Title")
       :EntryId (object
                  {:Id (xpath "/DIF/Entry_ID")})
       :Abstract (xpath "/DIF/Summary/Abstract")})))