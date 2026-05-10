;; DynamicLayout Clojure API — generate layout JSON from Clojure code.
;; Single-file. Zero dependencies. Works on Clojure 1.11+ (JVM, Babashka).
;;
;; Example:
;;   (require '[dynamiclayout :as dl])
;;   (-> (dl/begin "My Page")
;;       (dl/fieldset "Info") (dl/label "Hello from Clojure!") (dl/end-fieldset)
;;       (dl/button "ok" "OK" "primary" true)
;;       (dl/end)
;;       (println))

(ns dynamiclayout)

(defn- putc [b c] (update b :buf str c))
(defn- puts [b s] (update b :buf str s))
(defn- indent [b] (-> b (putc \newline) (#(reduce puts % (repeat (:depth %) "  ")))))
(defn- cm [b] (if (:comma b) (putc (assoc b :comma false) \,) b))
(defn- esc [b s] (-> b (putc \") (#(reduce (fn [b c] (case c \" (puts b "\\\"") \\ (puts b "\\\\") \newline (puts b "\\n") (putc b c))) % s)) (putc \")))
(defn- kv [b k v] (-> b cm (putc \,) indent (esc k) (puts ": ") (esc v) (assoc :comma true)))
(defn- kvint [b k v] (-> b cm (putc \,) indent (esc k) (puts (str ": " v)) (assoc :comma true)))
(defn- kvbool [b k] (-> b cm (putc \,) indent (esc k) (puts ": true") (assoc :comma true)))
(defn- obj [b] (-> b cm (putc \,) indent (putc \{) (update :depth inc) (assoc :comma false)))
(defn- co [b] (-> b (update :depth dec) indent (putc \}) (assoc :comma true)))
(defn- arr [b k] (-> b cm (putc \,) indent (esc k) (puts ": [") (update :depth inc) (assoc :comma false)))
(defn- ca [b] (-> b (update :depth dec) indent (putc \]) (assoc :comma true)))
(defn- key [b p] (let [c (inc (:cnt b))] [(assoc b :cnt c) (str p "_" c)]))

(defn begin [title] (-> {:buf "" :depth 2 :comma false :cnt 0} (puts "{\"ui\":{") (kv "title" title) (arr "layout")))

(defn end [b] (-> b ca (assoc :comma false) (putc \,) (puts "\"translations\":{},") (puts "\"userAccess\":{\"cancel\":true}") (puts "}}") :buf))

(defn fieldset [b title] (let [[b k] (key b "fs")] (-> b obj (kv "type" "FIELDSET") (kv "key" k) (kv "title" title) (arr "content"))))
(defn end-fieldset [b] (-> b ca co))
(defn row [b] (let [[b k] (key b "r")] (-> b obj (kv "type" "ROW") (kv "key" k) (arr "content"))))
(defn end-row [b] (-> b ca co))
(defn label [b text] (let [[b k] (key b "l")] (-> b obj (kv "type" "LABEL") (kv "key" k) (kv "label" text) co)))
(defn alert [b msg & [color]] (let [[b k] (key b "a")] (-> b obj (kv "type" "ALERT") (kv "key" k) (kv "message" msg) (kv "color" (or color "info")) co)))
(defn badge [b title & [color]] (let [[b k] (key b "bd")] (-> b obj (kv "type" "BADGE") (kv "key" k) (kv "title" title) (kv "color" (or color "primary")) co)))
(defn spacer [b & [px]] (let [[b k] (key b "sp")] (-> b obj (kv "type" "SPACER") (kv "key" k) (kvint "width" (or px 20)) co)))
(defn input [b id label & {:keys [required]}] (let [[b k] (key b "i")] (-> b obj (kv "type" "INPUT") (kv "key" k) (kv "id" id) (kv "label" label) (#(if required (kvbool % "required") %)) co)))
(defn checkbox [b id & [label]] (let [[b k] (key b "cb")] (-> b obj (kv "type" "CHECKBOX") (kv "key" k) (kv "id" id) (kv "label" (or label "")) co)))
(defn textarea [b id label & [rows]] (let [[b k] (key b "ta")] (-> b obj (kv "type" "TEXTAREA") (kv "key" k) (kv "id" id) (kv "label" label) (#(if (pos? (or rows 0)) (kvint % "rows" rows) %)) co)))
(defn rating [b id & [label]] (let [[b k] (key b "rt")] (-> b obj (kv "type" "RATING") (kv "key" k) (kv "id" id) (kv "label" (or label "")) co)))
(defn button [b id title color & [is-default]] (let [[b k] (key b "btn")] (-> b obj (kv "type" "BUTTON") (kv "key" k) (kv "id" id) (kv "title" title) (kv "color" color) (#(if is-default (kvbool % "default") %)) co)))
(defn section [b title text] (-> b (fieldset title) (label text) end-fieldset))
