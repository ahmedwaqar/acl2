;; Nat-listp.
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program; if not, write to the Free Software Foundation, Inc., 59 Temple
;; Place - Suite 330, Boston, MA 02111-1307, USA.

;; Note: Contributed initially by Sol Swords; modified by Matt Kaufmann.
;; Adapted from unicode/nat-listp.lisp, but INCOMPATIBLE with it.  This
;; version of nat-listp is similar to built-in ACL2 functions integer-listp,
;; symbol-listp, etc, in that it implies true-listp.

(in-package "ACL2")


(defund nat-listp (l)
  (declare (xargs :guard t))
  (cond ((atom l)
         (eq l nil))
        (t (and (natp (car l))
                (nat-listp (cdr l))))))

(local (in-theory (enable nat-listp)))

(defthm nat-listp-implies-true-listp
  (implies (nat-listp x)
           (true-listp x))
  :rule-classes (:rewrite :compound-recognizer))

(in-theory (disable (:rewrite nat-listp-implies-true-listp)))

(defthm nat-listp-when-not-consp
  (implies (not (consp x))
           (equal (nat-listp x)
                  (eq x nil)))
  :hints(("Goal" :in-theory (enable nat-listp))))

(defthm nat-listp-of-cons
  (equal (nat-listp (cons a x))
         (and (natp a)
              (nat-listp x)))
  :hints(("Goal" :in-theory (enable nat-listp))))

(defthm nat-listp-of-append
  (implies (true-listp x)
           (equal (nat-listp (append x y))
                  (and (nat-listp x)
                       (nat-listp y)))))

(defthm car-nat-listp
  (implies (and (nat-listp x)
                x)
           (natp (car x)))
  :rule-classes :forward-chaining)

(defthm nat-listp-of-cdr-when-nat-listp
  (implies (nat-listp x)
           (nat-listp (cdr x))))