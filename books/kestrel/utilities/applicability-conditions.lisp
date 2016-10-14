; Applicability Conditions
;
; Copyright (C) 2015-2016 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file provides utilities to manage logical formulas
; that must hold for certain event-generating macros to apply.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "std/util/defaggregate" :dir :system)
(include-book "event-forms")
(include-book "fresh-names")
(include-book "prove-interface")
(include-book "symbol-symbol-alists")

(local (set-default-parents applicability-conditions))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defsection applicability-conditions
  :parents (kestrel-utilities system-utilities)
  :short "Utilities to manage logical formulas that must hold
          for certain event-generating macros to apply."
  :long
  "<p>
   For instance,
   transforming a function into a new function according to some criteria
   may be subject to conditions that must hold (i.e. must be proved as theorems)
   for the transformation to successfully take place.
   </p>")

(std::defaggregate applicability-condition
  :short "Records to describe and manipulate applicability conditions."
  ((name symbolp "Name of the applicability condition.")
   (formula "The statement of the applicability condition
             (an untranslated @(see term)).")
   (hints "Hints to prove the applicability condition (possibly @('nil')).")))

(std::deflist applicability-condition-listp (x)
  (applicability-condition-p x)
  :short "Recognize @('nil')-terminated lists of applicability conditions."
  :true-listp t
  :elementp-of-nil nil)

(define prove-applicability-condition ((app-cond applicability-condition-p)
                                       (verbose booleanp)
                                       state)
  :returns (mv (success "A @(tsee booleanp).")
               (msg "A @('msgp') (see @(tsee msg)).")
               state)
  :mode :program
  :short "Try to prove the applicability condition."
  :long
  "<p>
   Besides returning an indication of success,
   return a structured message (printable with @('~@')).
   When the proof fails, the message is an error message.
   When the proof succeeds, currently the message is empty,
   but future versions of this code could return an informative message instead.
   </p>
   <p>
   If an error occurs during the proof attempt,
   the proof is regarded as having failed.
   </p>
   <p>
   If the @('verbose') argument is @('t'),
   also print a progress message to indicate that
   the proof of the applicability condition is being attempted,
   and then to indicate the outcome of the attempt.
   </p>
   <p>
   Parentheses are printed around the progress message
   to ease navigation in an Emacs buffer.
   </p>"
  (b* ((name (applicability-condition->name app-cond))
       (formula (applicability-condition->formula app-cond))
       (hints (applicability-condition->hints app-cond))
       ((run-when verbose)
        (cw "(Proving applicability condition ~x0:~%~x1~|" name formula))
       ((mv erp yes/no state) (prove$ formula :hints hints)))
    (cond (erp (b* (((run-when verbose)
                     (cw "Prover error.)~%~%")))
                 (mv nil
                     (msg "Prover error ~x0 ~
                           when attempting to prove ~
                           the applicability condition ~x1:~%~x2~|"
                          erp name formula)
                     state)))
          (yes/no (b* (((run-when verbose)
                        (cw "Done.)~%~%")))
                    (mv t "" state)))
          (t (b* (((run-when verbose)
                   (cw "Failed.)~%~%")))
               (mv nil
                   (msg "The applicability condition ~x0 fails:~%~x1~|"
                        name formula)
                   state))))))

(define prove-applicability-conditions
  ((app-conds applicability-condition-listp)
   (verbose booleanp)
   state)
  :returns (mv (success "A @(tsee booleanp).")
               (msg "A @('msgp') (see @(tsee msg)).")
               state)
  :mode :program
  :short "Try to prove a list of applicability conditions, one after the other."
  :long
  "<p>
   Besides returning an indication of success,
   return a structured message (printable with @('~@')).
   When the proof of an applicability condition fails,
   the message is the error message generated by that proof attempt.
   When all the proofs of the applicability conditions succeed,
   currently the message is empty,
   but future versions of this code could return an informative message instead.
   </p>
   <p>
   If the @('verbose') argument is @('t'),
   also print progress messages for the applicability conditions.
   </p>"
  (cond ((endp app-conds) (mv t "" state))
        (t (b* ((app-cond (car app-conds))
                ((mv success msg state)
                 (prove-applicability-condition app-cond verbose state)))
             (if success
                 (prove-applicability-conditions (cdr app-conds) verbose state)
               (mv nil msg state))))))

(define ensure-applicability-conditions
  ((app-conds applicability-condition-listp)
   (verbose booleanp)
   (ctx "Context for errors.")
   state)
  :returns (mv (erp "@(tsee Booleanp) flag of the
                     <see topic='@(url error-triple)'>error triple</see>.")
               (nothing "Always @('nil').")
               state)
  :mode :program
  :short "Cause a soft error if the proof of any applicability condition fails."
  :long
  "<p>
   Use the message from the applicability condition proof failure
   as error message.
   </p>"
  (b* (((mv success msg state) (prove-applicability-conditions
                                app-conds verbose state))
       ((unless success) (er soft ctx "~@0" msg)))
    (value nil)))

(define applicability-condition-event
  ((app-cond applicability-condition-p)
   (local booleanp "Make the theorem local or not.")
   (enabled booleanp "Leave the theorem enabled or not.")
   (rule-classes true-listp "Rule classes for the theorem.")
   (names-to-avoid symbol-listp "Avoid these as theorem name.")
   (wrld plist-worldp))
  :guard (or rule-classes enabled)
  :returns (mv (thm-name "A @(tsee symbolp).")
               (thm-event "A @(tsee pseudo-event-formp)."))
  :mode :program
  :short "Generate theorem event form for applicability condition."
  :long
  "<p>
   The name of the theorem is made fresh in the world,
   and not among the names to avoid,
   by adding @('$') signs to the applicabiilty condition's name, if needed.
   Besides the theorem event form,
   return the name of the theorem
   (which may be the same as the name of the applicability condition).
   </p>
   <p>
   The generated theorem must be enabled if it has no rule classes,
   as required by the guard of this function.
   </p>"
  (b* ((defthm/defthmd (if enabled 'defthm 'defthmd))
       (name (applicability-condition->name app-cond))
       (formula (applicability-condition->formula app-cond))
       (hints (applicability-condition->hints app-cond))
       (thm-name (fresh-name-in-world-with-$s name names-to-avoid wrld))
       (thm-event `(,defthm/defthmd ,thm-name
                     ,formula
                     :hints ,hints
                     :rule-classes ,rule-classes))
       (thm-event (if local
                      `(local ,thm-event)
                    thm-event)))
    (mv thm-name thm-event)))

(define applicability-condition-events
  ((app-conds applicability-condition-listp)
   (locals boolean-listp "Make theorems local or not.")
   (enableds boolean-listp "Leave the theorems enabled or not.")
   (rule-classess "Rule classes for the theorems.")
   (names-to-avoid "Avoid these as theorem names.")
   (wrld plist-worldp))
  :guard (and (= (len locals) (len app-conds))
              (= (len enableds) (len app-conds))
              (= (len rule-classess) (len app-conds)))
  :returns (mv (names-to-thm-names "A @(tsee symbol-symbol-alistp)
                                    of length @('(len app-conds)').")
               (thm-events "A @(tsee pseudo-event-form-listp)
                            of length @('(len app-conds)')."))
  :mode :program
  :short "Generate theorem event forms for applicability conditions."
  :long
  "<p>
   Repeatedly call @(tsee applicability-condition-event)
   on each applicability condition
   and corresponding @('local'), @('enabled'), and @('rule-classes') elements
   from the argument lists.
   Besides the list of theorem event forms,
   return an alist from the names of the applicability conditions
   to the corresponding theorem names
   (some of which may be the same as the names of the applicability conditions).
   </p>
   <p>
   As new theorem event forms are generated,
   their names are added to the names to avoid,
   because the theorem events are not in the ACL2 world yet.
   </p>"
  (b* (((mv names-to-thm-names rev-thm-events)
        (applicability-condition-events-aux app-conds
                                            locals
                                            enableds
                                            rule-classess
                                            names-to-avoid
                                            wrld
                                            nil
                                            nil)))
    (mv names-to-thm-names rev-thm-events))

  :prepwork
  ((define applicability-condition-events-aux
     ((app-conds applicability-condition-listp)
      (locals boolean-listp)
      (enableds boolean-listp)
      (rule-classess)
      (names-to-avoid)
      (wrld plist-worldp)
      (names-to-thm-names symbol-symbol-alistp)
      (rev-thm-events pseudo-event-form-listp))
     :guard (and (= (len locals) (len app-conds))
                 (= (len enableds) (len app-conds))
                 (= (len rule-classess) (len app-conds)))
     :returns (mv final-names-to-thm-names final-thm-events)
     :parents nil
     :mode :program
     (cond ((endp app-conds) (mv names-to-thm-names (reverse rev-thm-events)))
           (t (b* (((mv thm-name thm-event-form)
                    (applicability-condition-event (car app-conds)
                                                   (car locals)
                                                   (car enableds)
                                                   (car rule-classess)
                                                   names-to-avoid
                                                   wrld))
                   (new-names-to-avoid (cons thm-name names-to-avoid))
                   (new-names-to-thm-names
                    (acons (applicability-condition->name (car app-conds))
                           thm-name
                           names-to-thm-names))
                   (new-rev-thm-events
                    (cons thm-event-form rev-thm-events)))
                (applicability-condition-events-aux (cdr app-conds)
                                                    (cdr locals)
                                                    (cdr enableds)
                                                    (cdr rule-classess)
                                                    new-names-to-avoid
                                                    wrld
                                                    new-names-to-thm-names
                                                    new-rev-thm-events)))))))
