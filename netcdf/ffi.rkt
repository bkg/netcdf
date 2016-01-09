#lang racket/base

;; NetCDF FFI definitions

(require ffi/unsafe
         ffi/cvector
         ffi/unsafe/define
         "ffi-constants.rkt")

(provide (all-from-out "ffi-constants.rkt")
         (all-defined-out))

(define-ffi-definer define-netcdf (ffi-lib "libnetcdf"))

;; Represents a NetCDF "Variable".
(struct variable (id netcdf-id name dtype ndims dims nattrs))
(define _variable
  (make-ctype _int variable-id #f))

;; Returns the corresponding Racket type for a NetCDF data type.
(define (data-type->type data-type)
  (case data-type
    ;[(NC_NAT) (error 'data-type->type "not a type")]
    [(NC_BYTE NC_CHAR) _byte]
    [(NC_SHORT) _word]
    [(NC_INT) _int]
    [(NC_LONG) _long]
    [(NC_FLOAT) _float]
    ;[(NC_DOUBLE) _double]
    [(NC_DOUBLE) _double*]
    [(NC_UBYTE) _ubyte]
    [(NC_USHORT) _ushort]
    [(NC_UINT) _uint]
    [(NC_INT64) _int64]
    [(NC_UINT64) _uint64]
    [(NC_STRING) _string]))

;; Return the NetCDF library version.
(define-netcdf nc_inq_libvers
  (_fun -> _string))

;; Check return status
(define (check status source)
  (unless (zero? status)
    (error source (nc_strerror status))))

(define-netcdf nc_strerror
  (_fun _int -> _string))

(define _open-mode
  (_bitmask '(read = #x0000
              read/write = #x0001
              diskless = #x0008
              mmap = #x0010
              shared = #x0800
              mpi-io = #x2000
              mpi-posix = #x4000
              parallel = #x8000)))

(define _create-mode
  (_bitmask '(clobber = #x0000
              no-clobber = #x0004
              diskless = #x0008
              mmap = #x0010
              shared = #x0800
              classic = #x0100
              64-bit = #x0200
              netcdf4 = #x1000
              mpi-io = #x2000
              mpi-posix = #x4000)))

(define _dataset-type
  (_enum '(NC_FORMAT_CLASSIC = 1
           NC_FORMAT_64BIT
           NC_FORMAT_NETCDF4
           NC_FORMAT_NETCDF4_CLASSIC)))

(define _dataset-extended-type
  (_enum '(NC_FORMAT_UNDEFINED
           NC_FORMAT_NC3
           NC_FORMAT_NC_HDF5
           NC_FORMAT_NC_HDF4
           NC_FORMAT_PNETCDF
           NC_FORMAT_DAP2
           NC_FORMAT_DAP4)))

(define _data-type
  (_enum '(NC_NAT = 0
           NC_BYTE = 1
           NC_CHAR = 2
           NC_SHORT = 3
           NC_INT =  4
           ; Deprecated alias kept for backward compat.
           NC_LONG = 4
           NC_FLOAT = 5
           NC_DOUBLE = 6
           NC_UBYTE = 7
           NC_USHORT = 8
           NC_UINT = 9
           NC_INT64 = 10
           NC_UINT64 = 11
           NC_STRING = 12)))

(define _storage-type
  (_enum '(NC_CHUNKED
           NC_CONTIGUOUS)))

(define-netcdf nc_open
  (_fun (filename : _file)
        (mode : _open-mode)
        (netcdf-id : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_open) netcdf-id)))

(define-netcdf nc_create
  (_fun (filename : _file)
        (mode : _create-mode)
        (netcdf-id : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_create) netcdf-id)))

(define-netcdf nc_close
  (_fun (netcdf-id : _int)
        -> (result : _int)
        -> (check result 'nc_close)))

(define-netcdf nc_copy_var
  (_fun (_int = (variable-netcdf-id var))
        (var : _variable)
        (netcdf-id-out : _int)
        -> (result : _int)
        -> (check result 'nc_copy_var)))

(define-netcdf nc_def_dim
  (_fun (netcdf-id : _int)
        (dimname : _string)
        (dimlen : _size)
        (dimid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_def_dim) dimid)))

(define-netcdf nc_def_var
  (_fun (netcdf-id : _int)
        (varname : _string)
        (dtype : _data-type)
        (_int = (length dimlist))
        (dimlist : (_list i _int))
        (var-id : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_def_var) var-id)))

(define-netcdf nc_def_var_chunking
  (_fun (netcdf-id : _int)
        (var-id : _int)
        (storage : _storage-type)
        (chunk-size : (_list i _size))
        -> (result : _int)
        -> (check result 'nc_def_var_chunking)))

(define-netcdf nc_def_var_deflate
  (_fun (netcdf-id : _int)
        (var-id : _int)
        (shuffle? : _bool)
        (deflate? : _bool)
        (deflate-level : _int)
        -> (result : _int)
        -> (check result 'nc_def_var_deflate)))

(define-netcdf nc_inq_format
  (_fun (netcdf-id : _int)
        (nc-format : (_ptr o _dataset-type))
        -> (result : _int)
        -> (and (check result 'nc_inq_format) nc-format)))

(define-netcdf nc_inq_format_extended
  (_fun (netcdf-id : _int)
        (nc-format : (_ptr o _dataset-extended-type))
        (mode : (_ptr o _create-mode))
        -> (result : _int)
        -> (and (check result 'nc_inq_format_extended)
                (values nc-format mode))))

(define-netcdf nc_inq
  (_fun (netcdf-id : _int)
        (ndims : (_ptr o _int))
        (nvars : (_ptr o _int))
        (natts : (_ptr o _int))
        (unlimdim : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq)
                (values ndims nvars natts unlimdim))))

;; Returns the number of Dataset global attributes.
(define-netcdf nc_inq_natts
  (_fun (netcdf-id : _int)
        (natts : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_natts) natts)))

;; Returns the length and data type of a Dataset or Variable attribute.
(define-netcdf nc_inq_att
  (_fun (netcdf-id : _int)
        (var : _variable)
        (name : _string)
        (dtype : (_ptr o _data-type))
        (len : (_ptr o _size))
        -> (result : _int)
        -> (and (check result 'nc_inq_att)
                (values dtype len))))

;; Returns the length of a Dataset or Variable attribute.
(define-netcdf nc_inq_attlen
  (_fun (netcdf-id : _int)
        (var-id : _int)
        (name : _string)
        (len : (_ptr o _size))
        -> (result : _int)
        -> (and (check result 'nc_inq_attlen) len)))

;; Returns the Dataset or Variable attribute name corresponding to an attribute
;; index.
(define-netcdf nc_inq_attname
  (_fun (netcdf-id : _int)
        (var-id : _int)
        (attnum : _int)
        (attname : (_bytes o NC_MAX_NAME))
        -> (result : _int)
        -> (and (check result 'nc_inq_attname)
                (cast attname _bytes _string))))

;; Returns the number of Dimensions defined for a Dataset.
(define-netcdf nc_inq_ndims
  (_fun (netcdf-id : _int)
        (ndims : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_ndims) ndims)))

;; Returns the Dimension name and size.
(define-netcdf nc_inq_dim
  (_fun (netcdf-id : _int)
        (dimid : _int)
        (dimname : (_bytes o NC_MAX_NAME))
        (dimlen : (_ptr o _size))
        -> (result : _int)
        -> (and (check result 'nc_inq_dim)
                (values (cast dimname _bytes _string) dimlen))))

(define-netcdf nc_inq_dimid
  (_fun (netcdf-id : _int)
        (dimname : _string)
        (dimid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_dimid) dimid)))

(define-netcdf nc_inq_nvars
  (_fun (netcdf-id : _int)
        (nvars : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_nvars) nvars)))

(define-netcdf nc_inq_var
  (_fun (netcdf-id : _int)
        (var-id : _int)
        (varname : (_bytes o NC_MAX_NAME))
        (dtype : (_ptr o _data-type))
        (ndims : (_ptr o _int))
        (dimlist : (_list o _int ndims))
        (natts : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_var)
                (variable var-id netcdf-id
                          (cast varname _bytes _string)
                          dtype ndims dimlist natts))))

(define-netcdf nc_inq_varid
  (_fun (netcdf-id : _int)
        (varname : _string)
        (var-id : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_varid) var-id)))

(define-netcdf nc_inq_varnatts
  (_fun (_int = (variable-netcdf-id var))
        (var : _variable)
        (natts : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_varnatts) natts)))

(define-netcdf nc_inq_var_deflate
  (_fun (_int = (variable-netcdf-id var))
        (var : _variable)
        (shuffle? : (_ptr o _bool))
        (deflate? : (_ptr o _bool))
        (deflate-level : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_var_deflate)
                (list shuffle? deflate? deflate-level))))

(define-netcdf nc_get_att_text
  (_fun (netcdf-id : _int)
        (var-id : _int)
        (name : _string)
        (size : _? = (nc_inq_attlen netcdf-id var-id name))
        (value : (_bytes o size))
        -> (result : _int)
        -> (and (check result 'nc_get_att_text) (cast value _bytes _string))))

;; Read entire var in a single call.
(define-netcdf nc_get_var
  (_fun (_int = (variable-netcdf-id var))
        (var : _variable)
        (vec : (_cvector i))
        -> (result : _int)
        -> (and (check result 'nc_get_var) vec)))

;; Read into an array, no data type conversion is done.
(define-netcdf nc_get_vara
  (_fun (_int = (variable-netcdf-id var))
        (var : _variable)
        (start : (_list i _size))
        (counts : (_list i _size))
        (size : _? = (apply * counts))
        (type : _? = (data-type->type (variable-dtype var)))
        (vec : (_cvector o type size))
        -> (result : _int)
        -> (and (check result 'nc_get_vara) vec)))

(define-netcdf nc_put_att_text
  (_fun (netcdf-id : _int)
        (var-id : _int)
        (name : _string)
        (_size = (string-length value))
        (value : _string)
        -> (result : _int)
        -> (check result 'nc_put_att_text)))

;; Write the entire var with one call.
(define-netcdf nc_put_var
  (_fun (_int = (variable-netcdf-id var))
        (var : _variable)
        (arr : (_cvector i))
        -> (result : _int)
        -> (check result 'nc_put_var)))

(define-netcdf nc_put_vara
  (_fun (_int = (variable-netcdf-id var))
        (var : _variable)
        (start : (_list i _size))
        (counts : (_list i _size))
        (arr : (_cvector i))
        -> (result : _int)
        -> (check result 'nc_put_vara)))
