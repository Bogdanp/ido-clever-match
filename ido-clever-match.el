;;; ido-clever-match.el --- Alternative matcher for ido.

;; Copyright (C) 2015 Bogdan Paul Popa

;; Author: Bogdan Paul Popa <popa.bogdanp@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "24"))
;; Keywords: ido flex
;; URL: https://github.com/Bogdanp/ido-clever-match.el

;; This file is NOT part of GNU Emacs.

;;; License:

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
;; KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
;; WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; This is an alternative matcher for ido. To try it out simply run:
;;
;; M-x ido-clever-match-enable RET

;; You can turn it off with:
;;
;; M-x ido-clever-match-disable RET

;;; Code:
(with-no-warnings
  (require 'cl))

(require 'ido)
(require 'files)
(require 'subr-x)

(defvar ido-clever-match--none   #b0000000000000000)
(defvar ido-clever-match--mask   #b0000001111111111)
(defvar ido-clever-match--flex   #b0000010000000000)
(defvar ido-clever-match--substr #b0001000000000000)
(defvar ido-clever-match--prefix #b0010000000000000)
(defvar ido-clever-match--case   #b0100000000000000)
(defvar ido-clever-match--equal  #b1000000000000000)

(defvar ido-clever-match--cache nil)

(defun ido-clever-match--apply-mask (score)
  "Apply the score mask to SCORE and reverse it."
  (- ido-clever-match--mask
     (logand ido-clever-match--mask score)))

(defun* ido-clever-match--compute-flex-score (text item)
  "Compute the flex score for TEXT in ITEM.

Higher scores are worse."
  (let ((chars (length text)) (indexes 0)
	(current-index 0) (last-index 0)
	(score 0))
    (cl-loop
     for i from 0 to (1- chars) do
     (setq current-index (search (substring text i (1+ i)) item :start2 last-index))
     (if (not current-index)
	 (return-from nil)
       (setq indexes (1+ indexes))
       (setq score (+ score (- current-index last-index)))
       (setq last-index (1+ current-index))))

    (when (= chars indexes)
      score)))

(defun ido-clever-match--score (text item)
  "Score TEXT against ITEM."
  (let* ((hash-key (list text item))
	 (score (gethash hash-key ido-clever-match--cache)))
    (when (not score)
      (let* ((ignore-case (equal (downcase text) text))
	     (text (if ignore-case (downcase text) text))
	     (item (if ignore-case (downcase item) item))
	     index)
	(setq
	 score
	 (cond
	  ((> (length text)
	      (length item))
	   ido-clever-match--none)

	  ((equal text item)
	   ido-clever-match--equal)

	  ((string-prefix-p text item)
	   (logior ido-clever-match--prefix
		   (ido-clever-match--apply-mask (- (length item)
						    (length text)))))

	  ((setq score (search text item))
	   (logior ido-clever-match--substr
		   (ido-clever-match--apply-mask (+ score (- (length item)
							     (length text))))))

	  ((setq score (ido-clever-match--compute-flex-score text item))
	   (logior ido-clever-match--flex
	  	   (ido-clever-match--apply-mask score)))

	  (ido-clever-match--none)))

	(when (not ignore-case)
	  (setq score (logior score ido-clever-match--case)))))

    (puthash hash-key score ido-clever-match--cache)))

(defun ido-clever-match--match (items text)
  "Sort ITEMS against TEXT."
  (let ((buckets (make-hash-table)))
    (dolist (item items)
      (let ((score (ido-clever-match--score text item)))
	(when (> score 0)
	  (puthash score (cons item (gethash score buckets))
		   buckets))))

    (cl-loop
     for k in (sort (hash-table-keys buckets) #'>)
     nconc (reverse (gethash k buckets)))))

(defun ido-clever-match (f &rest args)
  "Advises around (F ARGS) to provide alternative matching."
  (let ((items (car args)))
    (if (equal "" ido-text)
	(apply f args)
      (ido-clever-match--match items ido-text))))

;;;###autoload
(defun ido-clever-match-reset-cache ()
  "Create a hash table representing the cache."
  (interactive)
  (setq ido-clever-match--cache (make-hash-table :test #'equal)))

;;;###autoload
(defun ido-clever-match-enable ()
  "Enable `ido-clever-match`."
  (interactive)
  (ido-clever-match-reset-cache)
  (advice-add #'ido-set-matches-1 :around #'ido-clever-match))

;;;###autoload
(defun ido-clever-match-disable ()
  "Disable `ido-clever-match`."
  (interactive)
  (advice-remove #'ido-set-matches-1 #'ido-clever-match))

(provide 'ido-clever-match)
;;; ido-clever-match.el ends here
