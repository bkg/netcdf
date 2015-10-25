#lang racket/base

(require racket/system
         ffi/unsafe
         ffi/cvector
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
(struct variable (id ncid name dtype ndims dims nattrs))

(define (dimensions ncid)
  (for/list ([i (in-range (nc_inq_ndims ncid))])
    (let-values ([(dimname dimlen) (nc_inq_dim ncid i)])
      (list dimname dimlen))))

(define (create-dimensions*! ncid . dims)
  (for/list ([dim (in-list dims)])
    (apply nc_def_dim ncid dim)))

(define (variables ncid)
  (for/list ([i (in-range (nc_inq_nvars ncid))])
    (make-variable i ncid)))

(define (variable-ref ncid name)
  (make-variable (nc_inq_varid ncid name) ncid))

(define (make-variable varid ncid)
  (apply variable varid ncid
         (call-with-values (lambda () (nc_inq_var ncid varid)) list)))

(define (create-variables*! ncid . vars)
  (for/list ([var (in-list vars)])
    (apply nc_def_var ncid var)))

(define (attributes ncid [var -1])
  (for/list ([i (in-range
                  (case var
                    [(-1) (nc_inq_natts ncid)]
                    [else (nc_inq_varnatts ncid var)]))])
    (let* ([attr (nc_inq_attname ncid var i)]
           [val (nc_get_att_text ncid var attr)])
      (list attr val))))

(define (make-dataset ncid path)
  (dataset ncid path
           (dimensions ncid)
           (variables ncid)
           #f))

(define (create-dataset path [mode 'clobber])
  (make-dataset (nc_create path mode) path))

(define (open-dataset path #:mode [mode 'read])
  (make-dataset (nc_open path mode) path))

(define (data-type->type data-type)
  (case data-type
    [(NC_BYTE NC_CHAR) _byte]
    [(NC_SHORT) _word]
    [(NC_INT) _int]
    [(NC_LONG) _long]
    [(NC_FLOAT) _float]
    [(NC_DOUBLE) _double*]
    [(NC_UBYTE) _ubyte]
    [(NC_USHORT) _ushort]
    [(NC_UINT) _uint]
    [(NC_INT64) _int64]
    [(NC_UINT64) _uint64]
    [(NC_STRING) _string]))

(define (put-variable-data! ncid varname data)
  (nc_put_var ncid (nc_inq_varid ncid varname) data))

(define (variable-update-data! var start counts data)
  ((variable-proc var) nc_put_vara start counts data))

(define ((variable-proc var) proc . args)
  (apply proc (variable-ncid var) (variable-id var) args))

(define variable-vec
  (case-lambda
    [(var)
     (define vec (make-cvector
                   (data-type->type (variable-dtype var))
                   (apply * (map cadr (dimensions (variable-ncid var))))))
     ((variable-proc var) nc_get_var vec)]
    [(var start counts) ((variable-proc var) nc_get_vara start counts)]))

(define (dataset-attr-set! ncid k v)
  (nc_put_att_text ncid -1 k v))

(define (string-nul-terminate str)
  (cond [(string-no-nuls? str) (string-append str "\0")]
        [else str]))

(define (set-attr! nc/var k v)
  (define v-term (string-nul-terminate v))
  (if (variable? nc/var)
    ((variable-proc nc/var) nc_put_att_text k v-term)
    (nc_put_att_text nc/var -1 k v-term)))

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
    (define dims (create-dimensions*! nc
                                      `("latitude" ,ny)
                                      `("longitude" ,nx)))
    (check-equal? (dimensions nc) '(("latitude" 6) ("longitude" 12)))

    (define vars (create-variables*! nc
                                     `("latitude" NC_FLOAT ,(take dims 1))
                                     `("longitude" NC_FLOAT ,(cdr dims))
                                     `("tmax" NC_FLOAT ,dims)))
    (define vlst (variables nc))
    (put-variable-data! nc "latitude"
                        (list->cvector (range 0.0 ny) _float))
    (put-variable-data! nc "longitude"
                        (list->cvector (range 0.0 nx) _float))
    (define tmax-cvec
      (list->cvector (build-list (* nx ny) (lambda (_) (random))) _float))
    (put-variable-data! nc "tmax" tmax-cvec)
    (define tmax-out-cvec (make-cvector _float (* nx ny)))
    (check-cvector-equal? (variable-vec (last vlst)) tmax-cvec)

    (define new-cvec (cvector _float 0.0 1.0 2.0 3.0))
    (variable-update-data! (last vlst) '(2 2) '(4 4) new-cvec)
    (check-cvector-equal? (nc_get_vara_float nc (last vars) '(2 2) '(4 4))
                          new-cvec)

    (set-attr! (car vlst) "units" "degrees_north")
    (check-equal? (nc_get_att_text nc (car vars) "units") "degrees_north")
    (set-attr! nc "title" "climate projections")))
