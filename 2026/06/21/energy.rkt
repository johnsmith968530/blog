;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/energy.rkt,v $
;; $Date: 2026/06/21 19:49:35 $
;; $Revision: 1.1 $

#lang racket

(provide barrel-of-oil-equivalent
         BTU
         gallon-of-gasoline
         kWh
         pound-of-propane)

;; International Table Btu, in joules.
(define BTU 1055.05585262)

;; Exact SI definition, in joules.
(define kWh 3600000.0)

;; Barrel of oil equivalent, in joules.
;;
;; Economist / energy-statistics convention:
;;   1 boe = 5.8e6 Btu
(define barrel-of-oil-equivalent (* 5800000 BTU))

;; 1 gallon of gasoline ≈ 121 MJ
(define gallon-of-gasoline 121e6)

;; 1 kg propane ≈ 46.4 MJ/kg lower heating value
;;                not counting heat recovered from water vapor
(define pound-of-propane (* 0.454 46.4e6))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
