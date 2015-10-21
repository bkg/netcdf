#lang racket/base

;; NetCDF FFI definitions

(require ffi/unsafe
         ffi/cvector
         ffi/unsafe/define
         "ffi-constants.rkt")

(provide (all-from-out "ffi-constants.rkt")
         (all-defined-out))

(define-ffi-definer define-netcdf (ffi-lib "libnetcdf"))

(define-cpointer-type _netcdf-dataset)

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

(define _nc-format
  (_enum '(NC_FORMAT_CLASSIC = 1
           NC_FORMAT_64BIT
           NC_FORMAT_NETCDF4
           NC_FORMAT_NETCDF4_CLASSIC)))

(define _nc-extended-format
  (_enum '(NC_FORMAT_UNDEFINED
           NC_FORMAT_NC3
           NC_FORMAT_NC_HDF5
           NC_FORMAT_NC_HDF4
           NC_FORMAT_PNETCDF
           NC_FORMAT_DAP2
           NC_FORMAT_DAP4)))

(define _data-type
  (_enum '(NC_NAT =  0
           NC_BYTE = 1
           NC_CHAR = 2
           NC_SHORT =  3
           NC_INT =  4
           NC_LONG = 4
           NC_FLOAT =  5
           NC_DOUBLE = 6
           NC_UBYTE =  7
           NC_USHORT = 8
           NC_UINT = 9
           NC_INT64 =  10
           NC_UINT64 = 11
           NC_STRING = 12)))

(define-netcdf nc_open
  (_fun (filename : _file)
        (mode : _open-mode)
        (ncid : (_ptr o _netcdf-dataset))
        -> (result : _int)
        -> (and (check result 'nc_open) ncid)))

(define-netcdf nc_create
  (_fun (filename : _file)
        (mode : _create-mode)
        (ncid : (_ptr o _netcdf-dataset))
        -> (result : _int)
        -> (and (check result 'nc_create) ncid)))

(define-netcdf nc_close
  (_fun _netcdf-dataset
        -> (result : _int)
        -> (check result 'nc_close)))

(define-netcdf nc_def_dim
  (_fun (ncid : _netcdf-dataset)
        (dimname : _string)
        (dimlen : _size)
        (dimid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_def_dim) dimid)))

(define-netcdf nc_def_var
  (_fun (ncid : _netcdf-dataset)
        (varname : _string)
        (dtype : _data-type)
        (ndims : _int)
        (dimlist : (_list i _int))
        (varid : (_ptr o _int))
        (varid : (_ptr o _netcdf-variable))
        -> (result : _int)
        -> (and (check result 'nc_def_var) varid)))

(define-netcdf nc_inq_format
  (_fun (ncid : _netcdf-dataset)
        (nc-format : (_ptr o _nc-format))
        -> (result : _int)
        -> (and (check result 'nc_inq_format) nc-format)))

(define-netcdf nc_inq_format_extended
  (_fun (ncid : _netcdf-dataset)
        (nc-format : (_ptr o _nc-extended-format))
        (mode : (_ptr o _create-mode))
        -> (result : _int)
        -> (and (check result 'nc_inq_format_extended)
                (values nc-format mode))))

(define-netcdf nc_inq
  (_fun (ncid : _netcdf-dataset)
        (ndims : (_ptr o _int))
        (nvars : (_ptr o _int))
        (natts : (_ptr o _int))
        (unlimdim : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq)
                (values ndims nvars natts unlimdim))))

(define-netcdf nc_inq_dim
  (_fun (ncid : _netcdf-dataset)
        (dimid : _int)
        (dimname : (_bytes o NC_MAX_NAME))
        (dimlen : (_ptr o _size))
        -> (result : _int)
        -> (values (cast dimname _bytes _string)
                   dimlen)))

(define-netcdf nc_inq_dimid
  (_fun (ncid : _netcdf-dataset)
        (dimname : _string)
        (dimid : (_ptr o _int))
        -> (result : _int)
        -> (and (check result 'nc_inq_dimid) dimid)))

(define-netcdf nc_inq_var
  (_fun (ncid : _netcdf-dataset)
        (varid : _int)
        (varname : (_bytes o NC_MAX_NAME))
        (dtype : (_ptr o _data-type))
        (ndims : (_ptr o _int))
        (dimlist : (_list o _int ndims))
        (natts : (_ptr o _int))
        -> (result : _int)
        -> (values (cast varname _bytes _string)
                   dtype ndims dimlist natts)))

(define-netcdf nc_inq_varid
  (_fun (ncid : _netcdf-dataset)
        (varname : _string)
        (varid : (_ptr o _int))
        -> (result : _int)
        -> (values varid result)))

;; Read an array of values from a variable, converts data to output type as
;; needed.
(define-netcdf nc_get_vara_float
  (_fun (ncid : _netcdf-dataset)
        (varid : _int)
        (start : (_list i _size))
        (counts : (_list i _size))
        (size : _? = (apply * counts))
        (vect : (_ptr o (_array _float size)))
        -> (r : _int)
        -> vect))

;; Write the entire var with one call.
(define-netcdf nc_put_var
  (_fun (ncid : _netcdf-dataset)
        (varid : _int)
        (arr : (_cvector i))
        -> (result : _int)
        -> (check result 'nc_put_var)))

(define-netcdf nc_put_vara_float
  (_fun (ncid : _netcdf-dataset)
        (varid : _int)
        (start : (_list i _size))
        (counts : (_list i _size))
        (arr : (_vector i _float))
        -> (result : _int)
        -> (check result 'nc_put_vara_float)))
