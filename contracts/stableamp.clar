
;; title: StableAmp - Stablecoin Liquidity Amplification Protocol
;; version: 1.0.0
;; description: Built for Stacks blockchain with USDA integration

;; Import the SIP-010 trait for token interactions
(use-trait sip-010-trait .sip-010-trait.sip-010-trait)

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-INVALID-AMOUNT (err u403))
(define-constant ERR-POOL-NOT-FOUND (err u404))
(define-constant ERR-INSUFFICIENT-LIQUIDITY (err u405))
(define-constant ERR-TRANSFER-FAILED (err u406))

;; USDA token contract (Arkadiko's stablecoin)
(define-constant USDA-TOKEN 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token)

;; Data Variables
(define-data-var total-usda-deposited uint u0)
(define-data-var total-amplified-liquidity uint u0)
(define-data-var amplification-ratio uint u200) ;; 200% = 2x amplification
(define-data-var protocol-fee-rate uint u100) ;; 1% fee (100 basis points)
(define-data-var stx-rewards-pool uint u0)

;; User deposit tracking
(define-map user-deposits
  { user: principal }
  { 
    usda-amount: uint,
    amplified-liquidity: uint,
    entry-block: uint,
    rewards-earned: uint
  }
)

;; Liquidity pool state
(define-map pool-stats
  { pool-id: uint }
  {
    total-usda: uint,
    total-amplified: uint,
    trading-volume: uint,
    fees-collected: uint
  }
)

;; Read-only functions

;; Get user's deposit information
(define-read-only (get-user-deposit (user principal))
  (map-get? user-deposits { user: user })
)

;; Get total protocol statistics
(define-read-only (get-protocol-stats)
  {
    total-usda: (var-get total-usda-deposited),
    total-amplified: (var-get total-amplified-liquidity),
    amplification-ratio: (var-get amplification-ratio),
    stx-rewards: (var-get stx-rewards-pool)
  }
)

;; Calculate user's potential rewards
(define-read-only (get-user-rewards (user principal))
  (let ((deposit-info (unwrap! (get-user-deposit user) (err u0))))
    (let (
      (blocks-staked (- stacks-block-height (get entry-block deposit-info)))
      (base-rewards (/ (* (get amplified-liquidity deposit-info) blocks-staked) u1000))
    )
      (ok base-rewards)
    )
  )
)

;; Public functions

;; Deposit USDA and get amplified liquidity
(define-public (deposit-usda (amount uint) (usda-token <sip-010-trait>))
  (let (
    (amplified-amount (/ (* amount (var-get amplification-ratio)) u100))
    (existing-deposit (get-user-deposit tx-sender))
  )
    ;; Validate inputs
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq (contract-of usda-token) USDA-TOKEN) ERR-NOT-AUTHORIZED)
    
    ;; Transfer USDA from user to contract
    (try! (contract-call? usda-token transfer amount tx-sender (as-contract tx-sender) none))
    
    ;; Update user deposit record
    (match existing-deposit
      existing-info 
      ;; User has existing deposit - add to it
      (map-set user-deposits 
        { user: tx-sender }
        {
          usda-amount: (+ (get usda-amount existing-info) amount),
          amplified-liquidity: (+ (get amplified-liquidity existing-info) amplified-amount),
          entry-block: (get entry-block existing-info), ;; Keep original entry block
          rewards-earned: (get rewards-earned existing-info)
        }
      )
      ;; New user deposit
      (map-set user-deposits
        { user: tx-sender }
        {
          usda-amount: amount,
          amplified-liquidity: amplified-amount,
          entry-block: stacks-block-height,
          rewards-earned: u0
        }
      )
    )
    
    ;; Update global statistics
    (var-set total-usda-deposited (+ (var-get total-usda-deposited) amount))
    (var-set total-amplified-liquidity (+ (var-get total-amplified-liquidity) amplified-amount))
    
    ;; Return success with amplified amount
    (ok amplified-amount)
  )
)

;; Withdraw USDA and claim STX rewards
(define-public (withdraw-usda (amount uint) (usda-token <sip-010-trait>))
  (let (
    (user-deposit (unwrap! (get-user-deposit tx-sender) ERR-INSUFFICIENT-BALANCE))
    (user-usda-balance (get usda-amount user-deposit))
    (user-amplified (get amplified-liquidity user-deposit))
    (amplified-to-remove (/ (* amount (var-get amplification-ratio)) u100))
    (rewards (unwrap! (get-user-rewards tx-sender) (err u0)))
  )
    ;; Validate withdrawal
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= amount user-usda-balance) ERR-INSUFFICIENT-BALANCE)
    (asserts! (is-eq (contract-of usda-token) USDA-TOKEN) ERR-NOT-AUTHORIZED)
    
    ;; Transfer USDA back to user
    (try! (as-contract (contract-call? usda-token transfer amount tx-sender tx-sender none)))
    
    ;; Transfer STX rewards if available
    (if (and (> rewards u0) (>= (var-get stx-rewards-pool) rewards))
      (begin
        (try! (as-contract (stx-transfer? rewards tx-sender tx-sender)))
        (var-set stx-rewards-pool (- (var-get stx-rewards-pool) rewards))
      )
      true ;; No rewards available, continue anyway
    )
    
    ;; Update user deposit record
    (if (is-eq amount user-usda-balance)
      ;; Full withdrawal - remove user record
      (map-delete user-deposits { user: tx-sender })
      ;; Partial withdrawal - update record
      (map-set user-deposits
        { user: tx-sender }
        {
          usda-amount: (- user-usda-balance amount),
          amplified-liquidity: (- user-amplified amplified-to-remove),
          entry-block: (get entry-block user-deposit),
          rewards-earned: (+ (get rewards-earned user-deposit) rewards)
        }
      )
    )
    
    ;; Update global statistics
    (var-set total-usda-deposited (- (var-get total-usda-deposited) amount))
    (var-set total-amplified-liquidity (- (var-get total-amplified-liquidity) amplified-to-remove))
    
    (ok { usda-withdrawn: amount, stx-rewards: rewards })
  )
)

;; Simulate a trade using amplified liquidity (for demonstration)
(define-public (execute-amplified-trade (trade-amount uint))
  (let (
    (user-deposit (unwrap! (get-user-deposit tx-sender) ERR-INSUFFICIENT-BALANCE))
    (available-liquidity (get amplified-liquidity user-deposit))
    (fee-amount (/ (* trade-amount (var-get protocol-fee-rate)) u10000))
  )
    ;; Validate trade
    (asserts! (> trade-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= trade-amount available-liquidity) ERR-INSUFFICIENT-LIQUIDITY)
    
    ;; User pays fee in STX
    (try! (stx-transfer? fee-amount tx-sender (as-contract tx-sender)))
    
    ;; Add fee to rewards pool
    (var-set stx-rewards-pool (+ (var-get stx-rewards-pool) fee-amount))
    
    ;; Log the trade (in a real implementation, this would execute actual trading logic)
    (print { 
      event: "amplified-trade",
      user: tx-sender,
      trade-amount: trade-amount,
      fee-paid: fee-amount,
      available-liquidity: available-liquidity
    })
    
    (ok trade-amount)
  )
)

;; Admin function to adjust amplification ratio
(define-public (set-amplification-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= new-ratio u100) (<= new-ratio u500)) ERR-INVALID-AMOUNT) ;; 1x to 5x max
    (var-set amplification-ratio new-ratio)
    (ok true)
  )
)

;; Admin function to adjust fee rate
(define-public (set-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate u1000) ERR-INVALID-AMOUNT) ;; Max 10% fee
    (var-set protocol-fee-rate new-rate)
    (ok true)
  )
)
