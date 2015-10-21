#lang racket/base
(require ffi/unsafe
         ffi/unsafe/define)
(provide (all-defined-out))

(define-ffi-definer define-netcdf (ffi-lib "libnetcdf"))

(define (check status who)
  (unless (zero? status)
    (error who "failed: ~a" status)))

(define-netcdf nc_open
  (_fun (filename : _string)
        (mode : _int)
        (nc : (_ptr o _int))
        -> (result : _int)
        -> (values nc result)))

(define-netcdf nc_close 
  (_fun _int 
        -> (r : _int) 
        -> (check r 'nc_close)))

(define-netcdf nc_inq
  (_fun (ncid : _int)
        (ndims : (_ptr o _int))
        (nvars : (_ptr o _int))
        (natts : (_ptr o _int))
        (unlimdim : (_ptr o _int))
        -> (r : _int)
        -> (and (check r 'nc_inq) 
                (values ndims nvars natts unlimdim))))

(define-netcdf nc_inq_dim
  (_fun (ncid : _int)
        (dimid : _int)
        (dimname : (_bytes o 256))
        (dimlen : (_ptr o _size))
        -> (r : _int)
        -> (values (cast dimname _bytes _string) 
                   dimlen)))

(define-netcdf nc_inq_var
  (_fun (ncid : _int)
        (varid : _int)
        (varname : (_bytes o 256))
        (xtype : (_ptr o _int))
        (ndims : (_ptr o _int))
        (dimids : (_ptr o _int))
        (natts : (_ptr o _int))
        -> (result : _int)
        -> (values (cast varname _bytes _string) 
                   xtype ndims dimids natts)))

(define-netcdf nc_inq_varid
  (_fun (ncid : _int)
        (varname : _string)
        (varid : (_ptr o _int))
        -> (result : _int)
        -> (values varid result)))

(define-netcdf nc_get_vara_float
  (_fun (ncid : _int)
        (dimid : _int)
        (start : (_list i _size))
        (counts : (_list i _size))
        (size : _? = (apply * counts))
        (vect : (_ptr o (_array _float size)))
        -> (r : _int)
        -> vect))
