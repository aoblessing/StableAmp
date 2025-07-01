
;; title: sSIP-010 Fungible Token Standard Trait
;; version: 1.0.0
;; description: This trait defines the standard interface for fungible tokens on Stacks

(define-trait sip-010-trait
  (
    ;; Transfer from one principal to another
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    
    ;; Get the token name
    (get-name () (response (string-ascii 32) uint))
    
    ;; Get the token symbol  
    (get-symbol () (response (string-ascii 32) uint))
    
    ;; Get the number of decimal places
    (get-decimals () (response uint uint))
    
    ;; Get the balance of a principal
    (get-balance (principal) (response uint uint))
    
    ;; Get the total supply of tokens
    (get-total-supply () (response uint uint))
    
    ;; Get the token URI (optional)
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)
