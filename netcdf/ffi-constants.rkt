#lang racket/base

;; Constants from netcdf.h

(provide (all-defined-out))

; https://www.unidata.ucar.edu/software/netcdf/docs/netcdf_8h_source.html
; See: /usr/include/netcdf.h

;#define	NC_NAT 	        0	/**< Not A Type */
;#define	NC_BYTE         1	/**< signed 1 byte integer */
;#define	NC_CHAR 	2	/**< ISO/ASCII character */
;#define	NC_SHORT 	3	/**< signed 2 byte integer */
;#define	NC_INT 	        4	/**< signed 4 byte integer */
;#define NC_LONG         NC_INT  /**< deprecated, but required for backward compatibility. */
;#define	NC_FLOAT 	5	/**< single precision floating point number */
;#define	NC_DOUBLE 	6	/**< double precision floating point number */
;#define	NC_UBYTE 	7	/**< unsigned 1 byte int */
;#define	NC_USHORT 	8	/**< unsigned 2-byte int */
;#define	NC_UINT 	9	/**< unsigned 4-byte int */
;#define	NC_INT64 	10	/**< signed 8-byte int */
;#define	NC_UINT64 	11	/**< unsigned 8-byte int */
;#define	NC_STRING 	12	/**< string */

;/* Define the ioflags bits for nc_create and nc_open.
   ;currently unused: #x0010,#x0020,#x0040,#x0080
   ;and the whole upper 16 bits
;*/
(define NC_NOWRITE	 #x0000)	;/**< Set read-only access for nc_open(). */
(define NC_WRITE    	 #x0001)	;/**< Set read-write access for nc_open(). */
;/* unused: #x0002 */
(define NC_CLOBBER	 #x0000)      ;/**< Destroy existing file. Mode flag for nc_create(). */
(define NC_NOCLOBBER     #x0004)	;/**< Don't destroy existing file. Mode flag for nc_create(). */

(define NC_DISKLESS      #x0008)  ;/**< Use diskless file. Mode flag for nc_open() or nc_create(). */
(define NC_MMAP          #x0010)  ;/**< Use diskless file with mmap. Mode flag for nc_open() or nc_create(). */

(define NC_CLASSIC_MODEL #x0100)  ;/**< Enforce classic model. Mode flag for nc_create(). */
(define NC_64BIT_OFFSET  #x0200)  ;/**< Use large (64-bit) file offsets. Mode flag for nc_create(). */

;/** \deprecated The following flag currently is ignored, but use in
 ;* nc_open() or nc_create() may someday support use of advisory
 ;* locking to prevent multiple writers from clobbering a file
 ;*/
(define NC_LOCK          #x0400)

;/** Share updates, limit cacheing.
;Use this in mode flags for both nc_create() and nc_open(). */
(define NC_SHARE         #x0800)
;/**< Use netCDF-4/HDF5 format. Mode flag for nc_create(). */
(define NC_NETCDF4       #x1000)

;/** Turn on MPI I/O.
;Use this in mode flags for both nc_create() and nc_open(). */
(define NC_MPIIO         #x2000)
;/** Turn on MPI POSIX I/O.
;Use this in mode flags for both nc_create() and nc_open(). */
(define NC_MPIPOSIX      #x4000)
;/**< Use parallel-netcdf library. Mode flag for nc_open(). */
(define NC_PNETCDF       #x8000)

;/** Extended format specifier returned by  nc_inq_format_extended()
 ;*  Added in version 4.3.1. This returns the true format of the
 ;*  underlying data.
 ;* The function returns two values
 ;* 1. a small integer indicating the underlying source type
 ;*    of the data. Note that this may differ from what the user
 ;*    sees from nc_inq_format() because this latter function
 ;*    returns what the user can expect to see thru the API.
 ;* 2. A mode value indicating what mode flags are effectively
 ;*    set for this dataset. This usually will be a superset
 ;*    of the mode flags used as the argument to nc_open
 ;*    or nc_create.
 ;* More or less, the #1 values track the set of dispatch tables.
 ;* The #1 values are as follows.
 ;*/
;/**@ */
(define NC_FORMAT_UNDEFINED 0)
(define NC_FORMAT_NC3     1)
;/*cdf 4 subset of HDF5 */
(define NC_FORMAT_NC_HDF5 2)
;/* netcdf 4 subset of HDF4 */
(define NC_FORMAT_NC_HDF4 3)
(define NC_FORMAT_PNETCDF 4)
(define NC_FORMAT_DAP2    5)
(define NC_FORMAT_DAP4    6)


;/**
;Maximum for classic library.

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
;/**< max per variable dimensions */
(define NC_MAX_VAR_DIMS	1024)

;/** This is the max size of an SD dataset name in HDF4 (from HDF4 documentation).*/
(define NC_MAX_HDF4_NAME 64)
