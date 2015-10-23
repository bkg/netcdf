#lang racket/base

;; NetCDF FFI definitions

(require ffi/unsafe
         ffi/cvector
         ffi/unsafe/define
         "ffi-constants.rkt")

(provide (all-from-out "ffi-constants.rkt")
         (all-defined-out))

(define-ffi-definer define-netcdf (ffi-lib "libnetcdf"))

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
           ; Deprecated alias kept for backword compat.
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
        (ncid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_open) ncid)))

(define-netcdf nc_create
  (_fun (filename : _file)
        (mode : _create-mode)
        (ncid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_create) ncid)))

(define-netcdf nc_close
  (_fun (ncid : _int)
        -> (result : _int)
        -> (check result 'nc_close)))

(define-netcdf nc_def_dim
  (_fun (ncid : _int)
        (dimname : _string)
        (dimlen : _size)
        (dimid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_def_dim) dimid)))

(define-netcdf nc_def_var
  (_fun (ncid : _int)
        (varname : _string)
        (dtype : _data-type)
        (_int = (length dimlist))
        (dimlist : (_list i _int))
        (varid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_def_var) varid)))

(define-netcdf nc_def_var_chunking
  (_fun (ncid : _int)
        (varid : _int)
        (storage : _storage-type)
        (chunk-size : (_list i _size))
        -> (result : _int)
        -> (check result 'nc_def_var_chunking)))

(define-netcdf nc_def_var_deflate
  (_fun (ncid : _int)
        (varid : _int)
        (shuffle? : _int)
        (deflate? : _int)
        (deflate-level : _int)
        -> (result : _int)
        -> (check result 'nc_def_var_deflate)))

(define-netcdf nc_inq_format
  (_fun (ncid : _int)
        (nc-format : (_ptr o _dataset-type))
        -> (result : _int)
        -> (and (check result 'nc_inq_format) nc-format)))

(define-netcdf nc_inq_format_extended
  (_fun (ncid : _int)
        (nc-format : (_ptr o _dataset-extended-type))
        (mode : (_ptr o _create-mode))
        -> (result : _int)
        -> (and (check result 'nc_inq_format_extended)
                (values nc-format mode))))

(define-netcdf nc_inq
  (_fun (ncid : _int)
        (ndims : (_ptr o _int))
        (nvars : (_ptr o _int))
        (natts : (_ptr o _int))
        (unlimdim : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq)
                (values ndims nvars natts unlimdim))))

(define-netcdf nc_inq_nvars
  (_fun (ncid : _int)
        (nvars : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_nvars) nvars)))

(define-netcdf nc_inq_attlen
  (_fun (ncid : _int)
        (varid : _int)
        (name : _string)
        (len : (_ptr o _size))
        -> (result : _int)
        -> (and (check result 'nc_inq_attlen) len)))

(define-netcdf nc_inq_ndims
  (_fun (ncid : _int)
        (ndims : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_ndims) ndims)))

(define-netcdf nc_inq_dim
  (_fun (ncid : _int)
        (dimid : _int)
        (dimname : (_bytes o NC_MAX_NAME))
        (dimlen : (_ptr o _size))
        -> (result : _int)
        -> (and (check result 'nc_inq_dim)
                (values (cast dimname _bytes _string) dimlen))))

(define-netcdf nc_inq_dimid
  (_fun (ncid : _int)
        (dimname : _string)
        (dimid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_dimid) dimid)))

(define-netcdf nc_inq_var
  (_fun (ncid : _int)
        (varid : _int)
        (varname : (_bytes o NC_MAX_NAME))
        (dtype : (_ptr o _data-type))
        (ndims : (_ptr o _int))
        (dimlist : (_list o _int ndims))
        (natts : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_var)
                (values (cast varname _bytes _string)
                        dtype ndims dimlist natts))))

(define-netcdf nc_inq_varid
  (_fun (ncid : _int)
        (varname : _string)
        (varid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_varid) varid)))

(define-netcdf nc_get_att_text
  (_fun (ncid : _int)
        (varid : _int)
        (name : _string)
        (value : (_bytes o (nc_inq_attlen ncid varid name)))
        -> (result : _int)
        -> (and (check result 'nc_get_att_text) (cast value _bytes _string))))

;; Read entire var in a single call.
(define-netcdf nc_get_var
  (_fun (ncid : _int)
        (varid : _int)
        (vec : (_cvector i))
        -> (result : _int)
        -> (and (check result 'nc_get_var) vec)))

;; Read an array of values from a variable, converts data to output type as
;; needed.
(define-netcdf nc_get_vara_float
  (_fun (ncid : _int)
        (varid : _int)
        (start : (_list i _size))
        (counts : (_list i _size))
        (size : _? = (apply * (map - counts start)))
        (vec : (_cvector o _float size))
        -> (result : _int)
        -> (and (check result 'nc_get_vara_float) vec)))

(define-netcdf nc_put_att_text
  (_fun (ncid : _int)
        (varid : _int)
        (name : _string)
        (_size = (string-length value))
        (value : _string)
        -> (result : _int)
        -> (check result 'nc_put_att_text)))

;; Write the entire var with one call.
(define-netcdf nc_put_var
  (_fun (ncid : _int)
        (varid : _int)
        (arr : (_cvector i))
        -> (result : _int)
        -> (check result 'nc_put_var)))

(define-netcdf nc_put_vara_float
  (_fun (ncid : _int)
        (varid : _int)
        (start : (_list i _size))
        (counts : (_list i _size))
        (arr : (_cvector i))
        -> (result : _int)
        -> (check result 'nc_put_vara_float)))
