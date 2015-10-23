#lang racket/base

(require ffi/unsafe
         "ffi.rkt")

(provide
  ;; Returns an association list of dimension names and lengths.
  dimensions
  ;; Returns a Dataset struct from a supported path.
  open-dataset
  ;; Returns a list of Variable structs.
  variables)

(struct dataset (ptr path dimensions variables attrs))
;; Represents a NetCDF "Variable".
(struct variable (name dtype ndims dims nattrs))

(define (dimensions ncid)
  (for/list ([i (in-range (nc_inq_ndims ncid))])
    (let-values ([(dimname dimlen) (nc_inq_dim ncid i)])
      (list dimname dimlen))))

(define (make-dimensions* ncid . dims)
  (for/list ([dim (in-list dims)])
    (apply nc_def_dim ncid dim)))

(define (variables ncid)
  (for/list ([i (in-range (nc_inq_nvars ncid))])
    (call-with-values (lambda () (nc_inq_var ncid i)) variable)))

(define (make-variables* ncid . vars)
  (for/list ([var (in-list vars)])
    (apply nc_def_var ncid var)))

(define (make-dataset ncid path)
  (apply dataset ncid path
         (dimensions ncid)
         (variables ncid)
         #f))

(define (create-dataset path [mode 'clobber])
  (make-dataset (nc_create path mode) path))

(define (open-dataset path #:mode [mode 'read])
  (make-dataset (nc_open path mode) path))

(define (put-variable-data! ncid varname data)
  (nc_put_var ncid (nc_inq_varid ncid varname) data))


(module+ test
  (require rackunit
           racket/list
           ffi/cvector)

  (define-simple-check (check-cvector-equal? a b)
    (check-equal? (cvector->list a) (cvector->list b)))

  (test-case
    "Create NetCDF"
    (define nc (nc_create "test.nc" '(clobber diskless netcdf4)))
    (define nx 12)
    (define ny 6)
    (define dims (make-dimensions* nc
                                  `("latitude" ,ny)
                                  `("longitude" ,nx)))
    (check-equal? (dimensions nc) '(("latitude" 6) ("longitude" 12)))

    (define vars (make-variables* nc
                                 `("latitude" NC_FLOAT ,(take dims 1))
                                 `("longitude" NC_FLOAT ,(cdr dims))
                                 `("tmax" NC_FLOAT ,dims)))
    (put-variable-data! nc "latitude"
                        (list->cvector (range 0.0 ny) _float))
    (put-variable-data! nc "longitude"
                        (list->cvector (range 0.0 nx) _float))
    (define tmax-cvec
      (list->cvector (build-list (* nx ny) (lambda (_) (random))) _float))
    (put-variable-data! nc "tmax" tmax-cvec)
    (define tmax-out-cvec (make-cvector _float (* nx ny)))
    (check-cvector-equal? (nc_get_var nc (last vars) tmax-out-cvec) tmax-cvec)

    (define new-cvec (cvector _float 0.0 1.0 2.0 3.0))
    (nc_put_vara_float nc (last vars) '(2 2) '(4 4) new-cvec)
    (check-cvector-equal? (nc_get_vara_float nc (last vars) '(2 2) '(4 4))
                          new-cvec)

    (nc_put_att_text nc (car vars) "units" "degrees_north")
    (check-equal? (nc_get_att_text nc (car vars) "units") "degrees_north")))
