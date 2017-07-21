#lang racket
;; co2 Copyright (C) 2016 Dave Griffiths, 2017 Dustin Long
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(require data/gvector)


; Call-graph Associated Static Lexical Allocation

; During compilation, for each function body, collect the names of functions
; that get called. Use this list of function calls to build a call graph.
;
; Traverse the graph, and starting from the leaves, assign memory addresses
; to local variables and parameters. Each caller's starting memory address
; is equal to the maximum of the address used by its callees.

(define *func-nodes* (make-hash))

(struct func-node (name params calls [memory #:mutable]))

; Keep track of function name, its parameters, and its callees.
; Called by compiler after it finishes processing each function body.
(define (make-func-node! name params calls)
  (hash-set! *func-nodes* name (func-node name params calls #f)))

; Recursively resolve each function and its callees. Implicitly builds a total
; call graph of the entire program.
(define (resolve-func-node-memory n)
  (let* ((f (hash-ref *func-nodes* n))
         (name (func-node-name f))
         (params (func-node-params f))
         (calls (func-node-calls f))
         (memory (func-node-memory f)))
    (if (number? memory)
        memory ; return early
        (begin (let ((total 0)
                     (curr 0))
                 (for [(c calls)]
                   (set! curr (resolve-func-node-memory c))
                   (when (> curr total)
                     (set! total curr)))
                 (set! total (+ total (length params)))
                 (set-func-node-memory! f total)
                 total)))))

(define (casla->allocations)
  (let ((names (hash-keys *func-nodes*))
        (result (make-gvector)))
    ; Traverse the call-graph, assigning memory spaces.
    (for [(n names)]
      (resolve-func-node-memory n))
    ; For each function, allocate addresses to its locals and parameters.
    (for [(n names)]
         (let* ((f (hash-ref *func-nodes* n))
                (name (func-node-name f))
                (params (func-node-params f))
                (calls (func-node-calls f))
                (memory (func-node-memory f))
                (k (- memory (length params))))
           (for [(p params) (i (in-naturals))]
                (gvector-add! result (list name p (+ k i))))))
    (gvector->list result)))

(provide make-func-node!)
(provide casla->allocations)