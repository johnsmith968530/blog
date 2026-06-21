#!/usr/bin/env racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/currency.rkt,v $
;; $Date: 2026/06/21 19:48:20 $
;; $Revision: 1.1 $

#lang racket

;; Import with:
;;
;;   (require currency)
;;
;; Meaning:
;;   each constant is the approximate value of 1 unit of that currency
;;   in US dollars.
;;
;; Example:
;;   CNY = value of 1 Chinese yuan / renminbi in USD
;;   EUR = value of 1 euro in USD
;;   JPY = value of 1 Japanese yen in USD
;;
;; Snapshot date: 2026-06-21
;;
;; Naming:
;;   ISO 4217 alphabetic currency codes, uppercased as Racket identifiers.
;;
;; Caveat:
;;   These are constants, not live rates. Regenerate periodically if you
;;   need current exchange values.

(provide
 USD

 AED
 AUD
 BRL
 CAD
 CHF
 CNY
 CZK
 DKK
 EUR
 GBP
 HKD
 HUF
 IDR
 ILS
 INR
 JPY
 KRW
 MXN
 MYR
 NOK
 NZD
 PHP
 PLN
 RUB
 SAR
 SEK
 SGD
 THB
 TRY
 TWD
 VND
 ZAR)

;; Base currency
(define USD 1.0)

;; Major / commonly traded currencies.
;; Values are USD per 1 unit of the given currency.

(define AED 0.272294077604)       ; UAE dirham
(define AUD 0.701438369521)       ; Australian dollar
(define BRL 0.193951618769)       ; Brazilian real
(define CAD 0.706769723116)       ; Canadian dollar
(define CHF 1.239510641199)       ; Swiss franc
(define CNY 0.147297011461)       ; Chinese yuan / renminbi
(define CZK 0.047380596869)       ; Czech koruna
(define DKK 0.153693288137)       ; Danish krone
(define EUR 1.146815293929)       ; Euro
(define GBP 1.322872061074)       ; Pound sterling
(define HKD 0.127588336742)       ; Hong Kong dollar
(define HUF 0.003257937121)       ; Hungarian forint
(define IDR 0.0000562145869566)   ; Indonesian rupiah
(define ILS 0.337929170046)       ; Israeli new shekel
(define INR 0.010591957495)       ; Indian rupee
(define JPY 0.006202594039)       ; Japanese yen
(define KRW 0.000653165937)       ; South Korean won
(define MXN 0.057693909808)       ; Mexican peso
(define MYR 0.242062469061)       ; Malaysian ringgit
(define NOK 0.103167755620)       ; Norwegian krone
(define NZD 0.574069619719)       ; New Zealand dollar
(define PHP 0.016463459286)       ; Philippine peso
(define PLN 0.269370282316)       ; Polish zloty
(define RUB 0.013636346219)       ; Russian ruble
(define SAR 0.266666666667)       ; Saudi riyal
(define SEK 0.104392426162)       ; Swedish krona
(define SGD 0.774781182425)       ; Singapore dollar
(define THB 0.030410728516)       ; Thai baht
(define TRY 0.021526254960)       ; Turkish lira
(define TWD 0.031599280674)       ; New Taiwan dollar
(define VND 3.784907083995603e-5) ; Vietnamese đồng
(define ZAR 0.060767639919)       ; South African rand

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
