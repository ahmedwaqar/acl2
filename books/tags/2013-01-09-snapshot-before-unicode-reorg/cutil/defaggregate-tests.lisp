; CUTIL - Centaur Basic Utilities
; Copyright (C) 2008-2011 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2 of the License, or (at your option) any later
; version.  This program is distributed in the hope that it will be useful but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
; more details.  You should have received a copy of the GNU General Public
; License along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA.
;
; Original author: Jared Davis <jared@centtech.com>

; Tests for defaggregate utility.  Consider moving tests from the bottom of
; defaggregate.lisp into this file.

(in-package "CUTIL")

(include-book "defaggregate")
(include-book "deflist")

(encapsulate
 ()

 (defn foof-p (x)
   (keywordp x))

 (defmacro foom-p (x)
   (keywordp x))

 (defaggregate containerf
   (thing)
   :require ((foof-p-of-containerf->thing
              (foof-p thing)))
   :tag :containerf)

; The following defaggregate call is commented out because using a macro, as is
; done in the following example, results in a rewrite rule that is
; unacceptable.  Here is the error:

;;; ACL2 Error in ( DEFTHM FOOM-P-OF-CONTAINERM->THING ...):  A :REWRITE
;;; rule generated from FOOM-P-OF-CONTAINERM->THING is illegal because
;;; it rewrites the quoted constant 'NIL.  See :DOC rewrite.

 ;; (defaggregate containerm
 ;;   (thing)
 ;;   :require ((foom-p-of-containerm->thing
 ;;              (foom-p thing)))
 ;;   :tag :containerm)

 ) ; encapsulate

(mutual-recursion
 (DEFUND FOO-P (X)
   (DECLARE (XARGS :GUARD T))
   (AND (CONSP X)
        (EQ (CAR X) :FOO)
        (ALISTP (CDR X))
        (CONSP (CDR X))
        (LET ((BAR (CDR (ASSOC 'BAR (CDR X)))))
             (DECLARE (IGNORABLE BAR))
             (AND (FOO-LIST-P BAR)))))

 (DEFUND FOO-LIST-P (X)
   (DECLARE (XARGS :GUARD T
                   :NORMALIZE NIL
                   :VERIFY-GUARDS T
                   :GUARD-DEBUG NIL
                   :GUARD-HINTS NIL))
   (IF (CONSP X)
       (AND (FOO-P (CAR X))
            (FOO-LIST-P (CDR X)))
       (NULL X))))

(cutil::defaggregate foo
  (bar)
  :require ((foo-list-p-of-foo->bar
             (foo-list-p bar)))
  :already-definedp t
  :tag :foo)

(cutil::deflist foo-list-p (x)
  (foo-p x)
  :elementp-of-nil nil
  :already-definedp t
  :true-listp t)





#||

(logic)

(defaggregate taco
    (shell meat cheese lettuce sauce)
    :tag :taco
    :require ((integerp-of-taco->shell (integerp shell)
                                       :rule-classes ((:rewrite) (:type-prescription))))
    :long "<p>Additional documentation</p>"
    )

(defaggregate htaco
    (shell meat cheese lettuce sauce)
    :tag :taco
    :hons t
    :require ((integerp-of-htaco->shell (integerp shell)))
    :long "<p>Additional documentation</p>"
    )

(defaggregate untagged-taco
    (shell meat cheese lettuce sauce)
    :tag nil
    :hons t
    :require ((integerp-of-untagged-taco->shell (integerp shell)))
    :long "<p>Additional documentation</p>"
    )


;;  Basic binding tests

(b* ((?my-taco (make-taco :shell 5
                         :meat 'beef
                         :cheese 'swiss
                         :lettuce 'iceberg
                         :sauce 'green))
     ((taco x) my-taco)
     (five (+ 2 3)))
    (list :x.shell x.shell
          :x.lettuce x.lettuce
          :five five
          :my-taco my-taco))


;; I'd like something like this, but it looks like the b* machinery wants
;; at least one form.
;;
;; (b* ((?my-taco (make-taco :shell 5
;;                           :meat 'beef
;;                           :cheese 'swiss
;;                           :lettuce 'iceberg
;;                           :sauce 'green))
;;      ((taco my-taco))
;;      (five (+ 2 3)))
;;     (list :my-taco.shell my-taco.shell
;;           :my-taco.lettuce my-taco.lettuce
;;           :five five
;;           :my-taco my-taco))

(b* (((taco x)
      (make-taco :shell 5
                 :meat 'beef
                 :cheese 'swiss
                 :lettuce 'iceberg
                 :sauce 'green))
     (five (+ 2 3)))
    (list :x.shell x.shell
          :x.lettuce x.lettuce
          :five five))

;; Improper binding... fails nicely
(b* (((taco x y)
      (make-taco :shell 5
                 :meat 'beef
                 :cheese 'swiss
                 :lettuce 'iceberg
                 :sauce 'green))
     (five (+ 2 3)))
    (list :x.shell x.shell
          :x.lettuce x.lettuce
          :five five))

;; Unused binding collapses to nothing.  warning noted.
(b* (((taco x) (make-taco :shell 5
                          :meat 'beef
                          :cheese 'swiss
                          :lettuce 'iceberg
                          :sauce 'green))
     (five (+ 2 3)))
    five)

;; Good, inadvertent capture is detected
(b* ((foo (make-taco :shell 5
                     :meat 'beef
                     :cheese 'swiss
                     :lettuce 'iceberg
                     :sauce 'green))
     ((taco x) (identity foo))
     (bad      ACL2::|(IDENTITY FOO)|)
     (five     (+ 2 3)))
    (list :x.shell x.shell
          :x.lettuce x.lettuce
          :five five
          :bad bad))

||#