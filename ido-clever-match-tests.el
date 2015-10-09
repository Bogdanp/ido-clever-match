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

(deftest incompatible-strings-shouldnt-match
  (should (= (ido-clever-match--score "foo" "f") ido-clever-match--none))
  (should (= (ido-clever-match--score "x" "f") ido-clever-match--none)))

(deftest prefix-shorter-is-better
  (should (> (ido-clever-match--score "ido" "ido-clever-match.el")
	     (ido-clever-match--score "ido" "ido-clever-match-tests.el"))))

(deftest substr-shorter-is-better
  (should (> (ido-clever-match--score "clev" "ido-clever-match.el")
	     (ido-clever-match--score "clev" "ido-clever-match-tests.el"))))

(deftest exact-then-prefix-then-substr-then-flex-then-none
  (should (>
	   (ido-clever-match--score "install-package" "install-package")
	   (ido-clever-match--score "install" "install-package")
	   (ido-clever-match--score "package" "install-package")
	   (ido-clever-match--score "instpkg" "install-package")
	   (ido-clever-match--score "foo" "install-package"))))

(deftest prefix-deeper-is-worse
  (should (>
	   (ido-clever-match--score "package" "-package")
	   (ido-clever-match--score "package" "install-package")
	   (ido-clever-match--score "package" "try-install-package"))))

(deftest flex-higher-is-worse
  (should (<
	   (ido-clever-match--compute-flex-score "bha" "bha.py")
	   (ido-clever-match--compute-flex-score "bha" "b/handlers.py")
	   (ido-clever-match--compute-flex-score "bha" "baz/handlers.py")
	   (ido-clever-match--compute-flex-score "bha" "foo/bar/handlers.py"))))

(deftest flex-early-return
  (should (not (ido-clever-match--compute-flex-score "x" "abc"))))

(deftest matching
  (should (equal (ido-clever-match--match '("ido-mode" "ido-flex" "-ido") "ido")
		 '("ido-mode" "ido-flex" "-ido"))))

(provide 'ido-clever-match-tests)
;;; ido-clever-match-tests.el ends here
