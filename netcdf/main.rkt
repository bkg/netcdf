#lang racket/base

(require racket/system
         ffi/cvector
         "ffi.rkt")

(provide
  ;; Returns a Variable by name from a Dataset.
  dataset-ref
  ;; Returns an association list of dimension names and lengths.
  dimensions
  ;; Write dimensions to a Dataset.
  create-dimensions*!
  ;; Returns a Dataset struct for a newly created NetCDF resource.
  create-dataset
  ;; Returns a Dataset struct from a supported path.
  open-dataset
  ;; Returns a Variable or Dataset (global) attribute value.
  attribute
  ;; Returns all Variable or Dataset (global) attribute values.
  attributes
  ;; Sets Variable or Dataset (global) attribute values.
  set-attr!
  ;; Returns a list of Variable structs.
  variables
  ;; Write variables to a Dataset.
  create-variables*!
  ;; Returns a list of Variable attributes.
  variable-attributes
  ;; Returns a cvector of Variable data.
  variable-data
  variable-copy!
  ;; Returns a list of a Variable's dimensions.
  variable-dimensions
  ;; Returns a list of Variable dimension lengths.
  variable-shape)

(struct dataset (id path dimensions variables attrs))

(define (dimensions netcdf-id)
  (for/list ([i (in-range (nc_inq_ndims netcdf-id))])
    (make-dimension i netcdf-id)))

(define (make-dimension dimid netcdf-id)
  (call-with-values (lambda () (nc_inq_dim netcdf-id dimid)) cons))

(define (variable-dimensions var)
  (for/list ([i (in-list (variable-dims var))])
    (make-dimension i (variable-netcdf-id var))))

(define (create-dimensions*! netcdf-id . dims)
  (for/list ([dim (in-list dims)])
    (apply nc_def_dim netcdf-id dim)))

(define (variables netcdf-id)
  (for/list ([i (in-range (nc_inq_nvars netcdf-id))])
    (nc_inq_var netcdf-id i)))

(define (dataset-ref netcdf-id varname)
  (nc_inq_var netcdf-id (nc_inq_varid netcdf-id varname)))

(define (create-variables*! netcdf-id . vars)
  (for/list ([var (in-list vars)])
    (apply nc_def_var netcdf-id var)))

(define variable-copy!
  (case-lambda
    [(var data) (nc_put_var var data)]
    [(var start data)
     (nc_put_vara var start (list (cvector-length data)) data)]
    [(var start data counts) (nc_put_vara var start counts data)]))

(define ((variable-proc var) proc . args)
  (apply proc (variable-netcdf-id var) (variable-id var) args))

(define (make-variable-cvector var [size #f])
  (make-cvector (data-type->type (variable-dtype var))
                (or size (apply * (variable-shape var)))))

(define variable-data
  (case-lambda
    [(var) (nc_get_var var (make-variable-cvector var))]
    [(var start counts) (nc_get_vara var start counts)]))

(define (variable-shape var)
  (map cdr (variable-dimensions var)))

(define (attribute dv k)
  (if (variable? dv)
    ((variable-proc dv) nc_get_att_text k)
    (nc_get_att_text dv NC_GLOBAL k)))

(define (attributes netcdf-id)
  (for/list ([i (in-range (nc_inq_natts netcdf-id))])
    (let ([attr (nc_inq_attname netcdf-id NC_GLOBAL i)])
      (list attr (attribute netcdf-id attr)))))

(define (variable-attributes var)
  (for/list ([i (in-range (nc_inq_varnatts var))])
    (let ([attr ((variable-proc var) nc_inq_attname i)])
      (list attr (attribute var attr)))))

(define (set-attr! dv k v)
  ; Attribute strings must be null terminated.
  (let ([v-term (string-nul-terminate v)])
    (if (variable? dv)
      ((variable-proc dv) nc_put_att_text k v-term)
      (nc_put_att_text dv NC_GLOBAL k v-term))))

(define (make-dataset netcdf-id path)
  (dataset netcdf-id path
           (dimensions netcdf-id)
           (variables netcdf-id)
           #f))

(define (create-dataset path [mode 'clobber])
  (make-dataset (nc_create path mode) path))

(define (open-dataset path #:mode [mode 'read])
  (make-dataset (nc_open path mode) path))

(define (string-nul-terminate str)
  (cond [(string-no-nuls? str) (string-append str "\0")]
        [else str]))

(module+ test
  (require rackunit
           racket/list
           ffi/unsafe
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
    (check-equal? (dimensions nc) '(("latitude" . 6) ("longitude" . 12)))

    (create-variables*! nc `("latitude" NC_FLOAT ,(take dims 1))
                           `("longitude" NC_FLOAT ,(cdr dims))
                           `("tmax" NC_FLOAT ,dims))
    (define vars (variables nc))
    (variable-copy! (car vars) (list->cvector (range 0.0 ny) _float))
    (variable-copy! (cadr vars) (list->cvector (range 0.0 nx) _float))
    (define tmax-cvec
      (list->cvector (build-list (* nx ny) (lambda (_) (random))) _float))
    (nc_put_var (last vars) tmax-cvec)
    (check-cvector-equal? (variable-data (last vars)) tmax-cvec)
    (check-equal? (variable-shape (last vars)) (list ny nx))

    (define new-cvec (apply cvector _float (range 0.0 16.0)))
    (variable-copy! (last vars) '(2 2) new-cvec '(4 4))
    (check-cvector-equal? (variable-data (last vars) '(2 2) '(4 4)) new-cvec)

    (set-attr! (car vars) "units" "degrees_north")
    (check-equal? (attribute (car vars) "units") "degrees_north")
    (check-equal? (variable-attributes (car vars)) '(("units" "degrees_north")))

    (set-attr! nc "title" "climate projections")
    (check-equal? (attributes nc) '(("title" "climate projections")))
    (nc_close nc)))
