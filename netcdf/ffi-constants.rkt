#lang racket/base

;; Constants from netcdf.h

(provide (all-defined-out))

; Let nc__create() or nc__open() figure out a suitable buffer size.
(define NC_SIZEHINT_DEFAULT 0)
; In nc__enddef(), align to the buffer size.
;define NC_ALIGN_CHUNK ((size_t)(-1))
; Size argument to nc_def_dim() for an unlimited dimension.
;define NC_UNLIMITED 0L
; Attribute id to put/get a global attribute.
(define NC_GLOBAL -1)

;; Maximum for classic library.

;In the classic netCDF model there are maximum values for the number of
;dimensions in the file (\ref NC_MAX_DIMS), the number of global or per
;variable attributes (\ref NC_MAX_ATTRS), the number of variables in
;the file (\ref NC_MAX_VARS), and the length of a name (\ref
;NC_MAX_NAME).

;These maximums are enforced by the interface, to facilitate writing
;applications and utilities.  However, nothing is statically allocated
;to these sizes internally.

;These maximums are not used for netCDF-4/HDF5 files unless they were
;created with the ::NC_CLASSIC_MODEL flag.

;As a rule, NC_MAX_VAR_DIMS <= NC_MAX_DIMS.
(define NC_MAX_DIMS	1024)
(define NC_MAX_ATTRS	8192)
(define NC_MAX_VARS	8192)
(define NC_MAX_NAME	256)
; max per variable dimensions
(define NC_MAX_VAR_DIMS	1024)

; This is the max size of an SD dataset name in HDF4 (from HDF4 documentation).
(define NC_MAX_HDF4_NAME 64)
