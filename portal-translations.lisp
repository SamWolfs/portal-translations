(ql:quickload "cl-dbi")
(ql:quickload "cl-json")

(defparameter *langs* (list 'dutch 'english 'french 'german))
(defparameter *lang-codes* '((dutch . "nl_NL") (english . "en_GB") (french . "fr_FR") (german . "de_DE")))

(defun parse-record (record)
    (list (cadr record) (cadddr record)))

(defun portal-translations-to-stream (language stream)
    (dbi:with-connection (conn :mysql :host "192.168.212.21" :database-name "cef_portal" :username "PORTALUSER" :password "secret")
    (let* ((query (dbi:prepare conn "SELECT label_name, ? FROM translations where ? is not null"))
            (result (dbi:execute query language language))
            (translations (make-hash-table)))
        (loop for row = (dbi:fetch result)
            while row
            do (setf (gethash (car (parse-record row)) translations) (cadr (parse-record row))))
        (json:encode-json translations stream))))

(defun write-translation-file (lang)
    (with-open-file (file (format nil "./~A.json" (cdr (assoc lang *lang-codes*)))
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
        (portal-translations-to-stream lang file)))

(mapc #'write-translation-file *langs*)
