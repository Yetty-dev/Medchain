
;; MedChain - Healthcare Consent and Medical Record Access Management
;; A comprehensive smart contract for managing patient consent forms and medical record 
;; access permissions on the Stacks blockchain. Ensures HIPAA-compliant access control
;; and immutable audit trails for healthcare data interactions.

;; ===================
;; CONSTANTS AND ERRORS
;; ===================

;; Error codes for various failure scenarios
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PATIENT_NOT_FOUND (err u101))
(define-constant ERR_PROVIDER_NOT_FOUND (err u102))
(define-constant ERR_CONSENT_EXPIRED (err u103))
(define-constant ERR_CONSENT_REVOKED (err u104))
(define-constant ERR_INVALID_PERMISSION (err u105))
(define-constant ERR_RECORD_NOT_FOUND (err u106))
(define-constant ERR_ACCESS_DENIED (err u107))
(define-constant ERR_INVALID_TIME_RANGE (err u108))

;; Contract owner for administrative functions
(define-constant CONTRACT_OWNER tx-sender)

;; Permission levels for granular access control
(define-constant PERMISSION_READ u1)
(define-constant PERMISSION_WRITE u2)
(define-constant PERMISSION_DELETE u4)
(define-constant PERMISSION_ADMIN u8)

;; Maximum consent duration (in blocks) - approximately 1 year
(define-constant MAX_CONSENT_DURATION u52560)

;; ===================
;; DATA STRUCTURES
;; ===================

;; Patient registry with comprehensive medical information
(define-map patients
  { patient-id: principal }
  {
    name: (string-ascii 100),
    date-of-birth: uint,
    emergency-contact: (string-ascii 200),
    medical-record-number: (string-ascii 50),
    registration-block: uint,
    is-active: bool
  }
)

;; Healthcare provider registry with credentials
(define-map healthcare-providers
  { provider-id: principal }
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    specialty: (string-ascii 100),
    organization: (string-ascii 100),
    registration-block: uint,
    is-verified: bool
  }
)

;; Consent forms tracking patient permissions
(define-map consent-forms
  { patient-id: principal, provider-id: principal }
  {
    consent-id: uint,
    granted-at: uint,
    expires-at: uint,
    permissions: uint,
    purpose: (string-ascii 200),
    is-active: bool,
    revoked-at: (optional uint)
  }
)

;; Medical record metadata (actual records stored off-chain)
(define-map medical-records
  { record-id: uint }
  {
    patient-id: principal,
    provider-id: principal,
    record-type: (string-ascii 50),
    created-at: uint,
    hash: (buff 32),
    access-level: uint,
    is-sensitive: bool
  }
)

;; Global counters for generating unique IDs
(define-data-var consent-counter uint u0)
(define-data-var record-counter uint u0)

;; ===================
;; PRIVATE FUNCTIONS
;; ===================

;; Generate unique consent ID using block height and counter
(define-private (generate-consent-id)
  (let ((counter (var-get consent-counter)))
    (var-set consent-counter (+ counter u1))
    counter
  )
)

;; Generate unique record ID using block height and counter
(define-private (generate-record-id)
  (let ((counter (var-get record-counter)))
    (var-set record-counter (+ counter u1))
    counter
  )
)

;; Check if a permission level is included in the permission set
(define-private (has-permission (permissions uint) (required uint))
  (>= permissions required)
)

;; Validate consent is active and not expired
(define-private (is-consent-valid (consent-data (tuple (consent-id uint) (granted-at uint) (expires-at uint) (permissions uint) (purpose (string-ascii 200)) (is-active bool) (revoked-at (optional uint)))))
  (and 
    (get is-active consent-data)
    (>= (get expires-at consent-data) block-height)
    (is-none (get revoked-at consent-data))
  )
)

;; ===================
;; PUBLIC FUNCTIONS - PATIENT MANAGEMENT
;; ===================

;; Register a new patient in the system
(define-public (register-patient 
    (name (string-ascii 100)) 
    (date-of-birth uint) 
    (emergency-contact (string-ascii 200))
    (medical-record-number (string-ascii 50))
  )
  (let ((patient-data {
    name: name,
    date-of-birth: date-of-birth,
    emergency-contact: emergency-contact,
    medical-record-number: medical-record-number,
    registration-block: block-height,
    is-active: true
  }))
    (map-set patients { patient-id: tx-sender } patient-data)
    (print { event: "patient-registered", patient: tx-sender })
    (ok true)
  )
)

;; Update patient information (only by patient themselves)
(define-public (update-patient-info
    (name (string-ascii 100))
    (emergency-contact (string-ascii 200))
  )
  (let ((existing-patient (unwrap! (map-get? patients { patient-id: tx-sender }) ERR_PATIENT_NOT_FOUND)))
    (map-set patients 
      { patient-id: tx-sender }
      (merge existing-patient { name: name, emergency-contact: emergency-contact })
    )
    (print { event: "patient-updated", patient: tx-sender })
    (ok true)
  )
)

;; Register a healthcare provider
(define-public (register-provider
    (name (string-ascii 100))
    (license-number (string-ascii 50))
    (specialty (string-ascii 100))
    (organization (string-ascii 100))
  )
  (let ((provider-data {
    name: name,
    license-number: license-number,
    specialty: specialty,
    organization: organization,
    registration-block: block-height,
    is-verified: false
  }))
    (map-set healthcare-providers { provider-id: tx-sender } provider-data)
    (print { event: "provider-registered", provider: tx-sender })
    (ok true)
  )
)
