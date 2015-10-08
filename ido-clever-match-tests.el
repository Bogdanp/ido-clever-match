;;; ido-clever-match-tests.el --- Tests for ido-clever-match
;;; Commentary:
;;; Code:
(require 'ert)
(require 'ido-clever-match)

(defmacro deftest (name &rest body)
  "Define a test named NAME with BODY.

Ensures that the cache is empty before running BODY."
  `(ert-deftest ,name ()
     (ido-clever-match-reset-cache)
     ,@body))

(deftest incompatible-strings-shouldnt-match ()
  (should (= (ido-clever-match--score "foo" "f") ido-clever-match--none))
  (should (= (ido-clever-match--score "x" "f") ido-clever-match--none)))

(deftest prefix-shorter-is-better ()
  (should (> (ido-clever-match--score "ido" "ido-clever-match.el")
	     (ido-clever-match--score "ido" "ido-clever-match-tests.el"))))

(deftest substr-shorter-is-better ()
  (should (> (ido-clever-match--score "clev" "ido-clever-match.el")
	     (ido-clever-match--score "clev" "ido-clever-match-tests.el"))))

(provide 'ido-clever-match-tests)
;;; ido-clever-match-tests.el ends here