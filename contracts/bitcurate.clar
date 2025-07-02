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