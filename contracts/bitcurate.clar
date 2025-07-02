;; Title: BitCurate - Decentralized Content Curation Protocol
;; 
;; Summary: A Bitcoin-secured decentralized protocol that democratizes content 
;;          discovery through community-driven curation, transparent reputation 
;;          systems, and economic incentive alignment on the Stacks blockchain.
;;
;; Description: BitCurate transforms traditional content platforms by implementing
;;              a trustless ecosystem where content value is determined through
;;              collective community intelligence rather than opaque algorithms.
;;              
;;              Core Protocol Features:
;;              - Economic spam prevention through stake-based submissions
;;              - Weighted reputation system for quality-driven content discovery
;;              - Peer-to-peer creator monetization with zero platform fees
;;              - Democratic content moderation via community consensus
;;              - Multi-category content organization with dynamic expansion
;;              - Immutable content history and transparent governance
;;              - Bitcoin-level security inheritance through Stacks integration
;;
;;              Built for the decentralized web, BitCurate enables communities to
;;              self-organize around quality content while maintaining complete
;;              transparency and censorship resistance through blockchain technology.

;; PROTOCOL CONSTANTS & CONFIGURATION

(define-constant CONTRACT_OWNER tx-sender)

;; Protocol Error Definitions
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_CONTENT (err u101))
(define-constant ERR_CONTENT_EXISTS (err u102))
(define-constant ERR_CONTENT_NOT_FOUND (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))
(define-constant ERR_INVALID_CATEGORY (err u105))
(define-constant ERR_INVALID_FLAG_OPERATION (err u106))
(define-constant ERR_ARITHMETIC_OVERFLOW (err u107))
(define-constant ERR_INVALID_VOTE (err u108))
(define-constant ERR_INVALID_CONTENT_ID (err u109))

;; Protocol Configuration
(define-constant MINIMUM_URL_LENGTH u10)
(define-constant MAXIMUM_UINT_VALUE u340282366920938463463374607431768211455)

;; PROTOCOL STATE VARIABLES

(define-data-var content-submission-fee uint u10)
(define-data-var total-content-count uint u0)
(define-data-var available-categories 
  (list 10 (string-ascii 20)) 
  (list "Technology" "Science" "Art" "Politics" "Sports")
)

;; DATA STRUCTURES & STORAGE MAPS

;; Primary Content Registry
(define-map content-registry 
  { content-id: uint } 
  { 
    creator: principal, 
    title: (string-ascii 100), 
    url: (string-ascii 200), 
    category: (string-ascii 20),
    creation-block: uint, 
    community-score: int,
    total-rewards: uint,
    flag-count: uint
  }
)

;; Community Voting Records
(define-map user-votes 
  { voter: principal, content-id: uint } 
  { vote-value: int }
)

;; User Reputation System
(define-map user-reputation
  { user: principal }
  { reputation-score: int }
)

;; PRIVATE UTILITY FUNCTIONS

;; Verify content existence in registry
(define-private (content-exists (content-id uint))
  (is-some (map-get? content-registry { content-id: content-id }))
)

;; Content quality filter for public queries
(define-private (is-valid-content (content (optional {
    creator: principal, 
    title: (string-ascii 100), 
    url: (string-ascii 200), 
    category: (string-ascii 20),
    creation-block: uint, 
    community-score: int,
    total-rewards: uint,
    flag-count: uint
  })))
  (is-some content)
)

;; Quality threshold filter (non-negative community score)
(define-private (get-quality-content (id uint))
  (match (map-get? content-registry { content-id: id })
    content (if (>= (get community-score content) 0) (some content) none)
    none
  )
)

;; Sequential ID generator for batch operations
(define-private (generate-id-sequence (count uint))
  (let ((safe-limit (if (> count u10) u10 count)))
    (list
      (if (>= safe-limit u1) u1 u0)
      (if (>= safe-limit u2) u2 u0)
      (if (>= safe-limit u3) u3 u0)
      (if (>= safe-limit u4) u4 u0)
      (if (>= safe-limit u5) u5 u0)
      (if (>= safe-limit u6) u6 u0)
      (if (>= safe-limit u7) u7 u0)
      (if (>= safe-limit u8) u8 u0)
      (if (>= safe-limit u9) u9 u0)
      (if (>= safe-limit u10) u10 u0)
    )
  )
)

;; Zero value filter for list operations
(define-private (filter-non-zero (value uint))
  (not (is-eq value u0))
)

;; PUBLIC CONTENT MANAGEMENT FUNCTIONS

;; Submit new content to the community marketplace
(define-public (submit-content (title (string-ascii 100)) (url (string-ascii 200)) (category (string-ascii 20)))
  (let
    (
      (new-content-id (+ (var-get total-content-count) u1))
    )
    ;; Input validation
    (asserts! (and 
                (>= (len title) u1)
                (>= (len url) MINIMUM_URL_LENGTH)
                (>= (len category) u1)
              ) ERR_INVALID_CONTENT)
    (asserts! (> new-content-id (var-get total-content-count)) ERR_ARITHMETIC_OVERFLOW)
    (asserts! (is-some (index-of (var-get available-categories) category)) ERR_INVALID_CATEGORY)
    (asserts! (>= (stx-get-balance tx-sender) (var-get content-submission-fee)) ERR_INSUFFICIENT_FUNDS)
    
    ;; Process submission fee
    (try! (stx-transfer? (var-get content-submission-fee) tx-sender CONTRACT_OWNER))
    
    ;; Register content in blockchain
    (map-set content-registry
      { content-id: new-content-id }
      {
        creator: tx-sender,
        title: title,
        url: url,
        category: category,
        creation-block: stacks-block-height,
        community-score: 0,
        total-rewards: u0,
        flag-count: u0
      }
    )
    
    ;; Update global state
    (var-set total-content-count new-content-id)
    
    ;; Emit event for indexers
    (print { 
      event: "content-submitted", 
      content-id: new-content-id, 
      creator: tx-sender,
      category: category
    })
    
    (ok new-content-id)
  )
)

;; Community voting mechanism with reputation integration
(define-public (vote-on-content (content-id uint) (vote-value int))
  (let
    (
      (previous-vote (default-to 0 (get vote-value (map-get? user-votes { voter: tx-sender, content-id: content-id }))))
      (target-content (unwrap! (map-get? content-registry { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
      (voter-reputation (default-to { reputation-score: 0 } (map-get? user-reputation { user: tx-sender })))
    )
    ;; Validation checks
    (asserts! (content-exists content-id) ERR_CONTENT_NOT_FOUND)
    (asserts! (or (is-eq vote-value 1) (is-eq vote-value -1)) ERR_INVALID_VOTE)
    
    ;; Record user's vote
    (map-set user-votes
      { voter: tx-sender, content-id: content-id }
      { vote-value: vote-value }
    )
    
    ;; Update content community score
    (map-set content-registry
      { content-id: content-id }
      (merge target-content { 
        community-score: (+ (get community-score target-content) (- vote-value previous-vote)) 
      })
    )
    
    ;; Update voter reputation
    (map-set user-reputation
      { user: tx-sender }
      { reputation-score: (+ (get reputation-score voter-reputation) vote-value) }
    )
    
    ;; Emit voting event
    (print { 
      event: "content-voted", 
      content-id: content-id, 
      voter: tx-sender, 
      vote: vote-value 
    })
    
    (ok true)
  )
)

;; Direct creator monetization system
(define-public (reward-creator (content-id uint) (reward-amount uint))
  (let
    (
      (target-content (unwrap! (map-get? content-registry { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
    )
    ;; Validation
    (asserts! (content-exists content-id) ERR_CONTENT_NOT_FOUND)
    (asserts! (>= (stx-get-balance tx-sender) reward-amount) ERR_INSUFFICIENT_FUNDS)
    
    ;; Update content reward tracking
    (map-set content-registry
      { content-id: content-id }
      (merge target-content { 
        total-rewards: (+ (get total-rewards target-content) reward-amount) 
      })
    )
    
    ;; Execute reward transfer
    (try! (stx-transfer? reward-amount tx-sender (get creator target-content)))
    
    ;; Emit reward event
    (print { 
      event: "creator-rewarded", 
      content-id: content-id, 
      sender: tx-sender, 
      recipient: (get creator target-content), 
      amount: reward-amount 
    })
    
    (ok true)
  )
)

;; Community-driven content moderation
(define-public (flag-content (content-id uint))
  (let
    (
      (target-content (unwrap! (map-get? content-registry { content-id: content-id }) ERR_CONTENT_NOT_FOUND))
    )
    ;; Validation
    (asserts! (content-exists content-id) ERR_CONTENT_NOT_FOUND)
    (asserts! (not (is-eq (get creator target-content) tx-sender)) ERR_INVALID_FLAG_OPERATION)
    
    ;; Increment flag counter
    (map-set content-registry
      { content-id: content-id }
      (merge target-content { 
        flag-count: (+ (get flag-count target-content) u1) 
      })
    )
    
    ;; Emit moderation event
    (print { 
      event: "content-flagged", 
      content-id: content-id, 
      flagger: tx-sender 
    })
    
    (ok true)
  )
)

;; PUBLIC QUERY FUNCTIONS (READ-ONLY)

;; Retrieve complete content information
(define-read-only (get-content-info (content-id uint))
  (map-get? content-registry { content-id: content-id })
)

;; Get user's voting history for specific content
(define-read-only (get-user-vote (user principal) (content-id uint))
  (get vote-value (map-get? user-votes { voter: user, content-id: content-id }))
)

;; Platform statistics
(define-read-only (get-total-content-count)
  (var-get total-content-count)
)

;; User reputation lookup
(define-read-only (get-user-reputation (user principal))
  (default-to { reputation-score: 0 } (map-get? user-reputation { user: user }))
)

;; Generate content ID list for batch operations
(define-read-only (get-content-id-list (count uint))
  (filter filter-non-zero (generate-id-sequence count))
)

;; Curated content discovery (quality-filtered)
(define-read-only (get-trending-content (limit uint))
  (let
    (
      (total-content (var-get total-content-count))
      (safe-limit (if (> limit total-content) total-content limit))
    )
    (filter is-valid-content
      (map get-quality-content (get-content-id-list safe-limit))
    )
  )
)

;; ADMINISTRATIVE FUNCTIONS (GOVERNANCE)

;; Economic parameter adjustment
(define-public (update-submission-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee MAXIMUM_UINT_VALUE) ERR_ARITHMETIC_OVERFLOW)
    
    (var-set content-submission-fee new-fee)
    
    (print { 
      event: "fee-updated", 
      new-fee: new-fee 
    })
    
    (ok true)
  )
)

;; Content removal for policy violations
(define-public (remove-content (content-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (content-exists content-id) ERR_CONTENT_NOT_FOUND)
    
    (map-delete content-registry { content-id: content-id })
    
    (print { 
      event: "content-removed", 
      content-id: content-id 
    })
    
    (ok true)
  )
)

;; Dynamic category management
(define-public (add-content-category (new-category (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (< (len (var-get available-categories)) u10) ERR_INVALID_CATEGORY)
    (asserts! (>= (len new-category) u1) ERR_INVALID_CATEGORY)
    
    (var-set available-categories 
      (unwrap-panic (as-max-len? (append (var-get available-categories) new-category) u10))
    )
    
    (print { 
      event: "category-added", 
      category: new-category 
    })
    
    (ok true)
  )
)