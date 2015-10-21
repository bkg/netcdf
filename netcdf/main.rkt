#lang racket/base
(require ffi/unsafe 
         "ffi.rkt")

(define (dimensions ncid ndims)
  (for/list ([i (in-range ndims)])
    (let-values ([(dimname dimlen) (nc_inq_dim ncid i)])
      (list dimname dimlen))))

(define (variables ncid nvars)
  (for/list ([i (in-range nvars)])
    (call-with-values (lambda () (nc_inq_var ncid i)) list))) 
