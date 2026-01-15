
;; title: Mock USDA Token for Testing StableAmp Protocol
;; version: 1.0.0
;; description: This simulates the Arkadiko USDA token for local development

(impl-trait .sip-010-trait.sip-010-trait)

;; Define the token
(define-fungible-token mock-usda)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))

;; Variables
(define-data-var token-name (string-ascii 32) "Mock USD Arkadiko")
(define-data-var token-symbol (string-ascii 32) "mUSDA")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var token-decimals uint u6)

;; SIP-010 Functions

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) err-not-token-owner)
        (ft-transfer? mock-usda amount from to)
    )
)

(define-read-only (get-name)
    (ok (var-get token-name))
)

(define-read-only (get-symbol)
    (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
    (ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance mock-usda who))
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply mock-usda))
)

(define-read-only (get-token-uri)
    (ok (var-get token-uri))
)

;; Mint function for testing purposes
(define-public (mint (amount uint) (to principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ft-mint? mock-usda amount to)
    )
)

;; Burn function
(define-public (burn (amount uint) (from principal))
    (begin
        (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) err-not-token-owner)
        (ft-burn? mock-usda amount from)
    )
)

;; Initialize with some supply for testing
(ft-mint? mock-usda u1000000000000 contract-owner) ;; 1M tokens with 6 decimals
