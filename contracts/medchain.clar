
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

;; ===================
;; PUBLIC FUNCTIONS - CONSENT MANAGEMENT
;; ===================

;; Grant consent to a healthcare provider
(define-public (grant-consent
    (provider-id principal)
    (duration-blocks uint)
    (permissions uint)
    (purpose (string-ascii 200))
  )
  (let (
    (patient (unwrap! (map-get? patients { patient-id: tx-sender }) ERR_PATIENT_NOT_FOUND))
    (provider (unwrap! (map-get? healthcare-providers { provider-id: provider-id }) ERR_PROVIDER_NOT_FOUND))
    (consent-id (generate-consent-id))
    (capped-duration (if (<= duration-blocks MAX_CONSENT_DURATION) duration-blocks MAX_CONSENT_DURATION))
    (expires-at (+ block-height capped-duration))
  )
    ;; Ensure the provider is verified
    (asserts! (get is-verified provider) ERR_NOT_AUTHORIZED)
    
    ;; Ensure valid permission level
    (asserts! (and (>= permissions u1) (<= permissions u15)) ERR_INVALID_PERMISSION)
    
    ;; Create the consent record
    (map-set consent-forms
      { patient-id: tx-sender, provider-id: provider-id }
      {
        consent-id: consent-id,
        granted-at: block-height,
        expires-at: expires-at,
        permissions: permissions,
        purpose: purpose,
        is-active: true,
        revoked-at: none
      }
    )
    
    (print { 
      event: "consent-granted", 
      patient: tx-sender, 
      provider: provider-id,
      consent-id: consent-id,
      expires-at: expires-at
    })
    (ok consent-id)
  )
)

;; Revoke consent from a healthcare provider
(define-public (revoke-consent (provider-id principal))
  (let (
    (existing-consent (unwrap! (map-get? consent-forms { patient-id: tx-sender, provider-id: provider-id }) ERR_CONSENT_EXPIRED))
  )
    ;; Ensure consent is currently active
    (asserts! (get is-active existing-consent) ERR_CONSENT_REVOKED)
    
    ;; Update the consent to revoked status
    (map-set consent-forms
      { patient-id: tx-sender, provider-id: provider-id }
      (merge existing-consent {
        is-active: false,
        revoked-at: (some block-height)
      })
    )
    
    (print { 
      event: "consent-revoked", 
      patient: tx-sender, 
      provider: provider-id,
      revoked-at: block-height
    })
    (ok true)
  )
)

;; Update consent permissions (extend or modify)
(define-public (update-consent
    (provider-id principal)
    (new-permissions uint)
    (additional-blocks uint)
    (new-purpose (string-ascii 200))
  )
  (let (
    (existing-consent (unwrap! (map-get? consent-forms { patient-id: tx-sender, provider-id: provider-id }) ERR_CONSENT_EXPIRED))
    (capped-additional (if (<= additional-blocks MAX_CONSENT_DURATION) additional-blocks MAX_CONSENT_DURATION))
    (new-expires-at (+ (get expires-at existing-consent) capped-additional))
  )
    ;; Ensure consent is currently active and valid
    (asserts! (is-consent-valid existing-consent) ERR_CONSENT_EXPIRED)
    (asserts! (and (>= new-permissions u1) (<= new-permissions u15)) ERR_INVALID_PERMISSION)
    
    ;; Update the consent
    (map-set consent-forms
      { patient-id: tx-sender, provider-id: provider-id }
      (merge existing-consent {
        permissions: new-permissions,
        expires-at: new-expires-at,
        purpose: new-purpose
      })
    )
    
    (print { 
      event: "consent-updated", 
      patient: tx-sender, 
      provider: provider-id,
      new-expires-at: new-expires-at
    })
    (ok true)
  )
)

;; ===================
;; PUBLIC FUNCTIONS - MEDICAL RECORD MANAGEMENT
;; ===================

;; Create a new medical record entry (providers only)
(define-public (create-medical-record
    (patient-id principal)
    (record-type (string-ascii 50))
    (record-hash (buff 32))
    (access-level uint)
    (is-sensitive bool)
  )
  (let (
    (provider (unwrap! (map-get? healthcare-providers { provider-id: tx-sender }) ERR_NOT_AUTHORIZED))
    (patient (unwrap! (map-get? patients { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
    (consent (unwrap! (map-get? consent-forms { patient-id: patient-id, provider-id: tx-sender }) ERR_CONSENT_EXPIRED))
    (record-id (generate-record-id))
  )
    ;; Ensure provider is verified
    (asserts! (get is-verified provider) ERR_NOT_AUTHORIZED)
    
    ;; Ensure consent is valid and includes write permission
    (asserts! (is-consent-valid consent) ERR_CONSENT_EXPIRED)
    (asserts! (has-permission (get permissions consent) PERMISSION_WRITE) ERR_ACCESS_DENIED)
    
    ;; Create the record
    (map-set medical-records
      { record-id: record-id }
      {
        patient-id: patient-id,
        provider-id: tx-sender,
        record-type: record-type,
        created-at: block-height,
        hash: record-hash,
        access-level: access-level,
        is-sensitive: is-sensitive
      }
    )
    
    (print { 
      event: "record-created", 
      record-id: record-id,
      patient: patient-id,
      provider: tx-sender,
      record-type: record-type
    })
    (ok record-id)
  )
)

;; Access a medical record (with consent verification)
(define-public (access-medical-record (record-id uint))
  (let (
    (record (unwrap! (map-get? medical-records { record-id: record-id }) ERR_RECORD_NOT_FOUND))
    (patient-id (get patient-id record))
    (consent (unwrap! (map-get? consent-forms { patient-id: patient-id, provider-id: tx-sender }) ERR_CONSENT_EXPIRED))
  )
    ;; Ensure consent is valid and includes read permission
    (asserts! (is-consent-valid consent) ERR_CONSENT_EXPIRED)
    (asserts! (has-permission (get permissions consent) PERMISSION_READ) ERR_ACCESS_DENIED)
    
    ;; Log the access for audit trail
    (print { 
      event: "record-accessed", 
      record-id: record-id,
      provider: tx-sender,
      accessed-at: block-height
    })
    (ok record)
  )
)

;; ===================
;; PUBLIC FUNCTIONS - ADMINISTRATIVE
;; ===================

;; Verify a healthcare provider (admin only)
(define-public (verify-provider (provider-id principal))
  (let (
    (provider (unwrap! (map-get? healthcare-providers { provider-id: provider-id }) ERR_PROVIDER_NOT_FOUND))
  )
    ;; Ensure only contract owner can verify providers
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    ;; Update provider verification status
    (map-set healthcare-providers
      { provider-id: provider-id }
      (merge provider { is-verified: true })
    )
    
    (print { event: "provider-verified", provider: provider-id, verified-by: tx-sender })
    (ok true)
  )
)

;; Deactivate a patient account (admin only - for compliance)
(define-public (deactivate-patient (patient-id principal))
  (let (
    (patient (unwrap! (map-get? patients { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
  )
    ;; Ensure only contract owner can deactivate patients
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    ;; Update patient status
    (map-set patients
      { patient-id: patient-id }
      (merge patient { is-active: false })
    )
    
    (print { event: "patient-deactivated", patient: patient-id, deactivated-by: tx-sender })
    (ok true)
  )
)

;; Emergency access to medical record (admin only - for critical situations)
(define-public (emergency-access-record (record-id uint) (emergency-reason (string-ascii 200)))
  (let (
    (record (unwrap! (map-get? medical-records { record-id: record-id }) ERR_RECORD_NOT_FOUND))
  )
    ;; Ensure only contract owner can perform emergency access
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    ;; Log emergency access with detailed information
    (print { 
      event: "emergency-access", 
      record-id: record-id,
      accessed-by: tx-sender,
      reason: emergency-reason,
      patient: (get patient-id record),
      accessed-at: block-height
    })
    (ok record)
  )
)

;; ===================
;; PUBLIC FUNCTIONS - ADVANCED CONSENT FEATURES
;; ===================

;; Batch grant consent to multiple providers (convenience function)
(define-public (batch-grant-consent
    (providers (list 5 { provider: principal, duration: uint, permissions: uint, purpose: (string-ascii 200) }))
  )
  (let (
    (patient (unwrap! (map-get? patients { patient-id: tx-sender }) ERR_PATIENT_NOT_FOUND))
  )
    (fold process-consent-grant providers (ok (list)))
  )
)

;; Helper function for batch consent processing
(define-private (process-consent-grant 
    (consent-data { provider: principal, duration: uint, permissions: uint, purpose: (string-ascii 200) })
    (acc (response (list 5 uint) uint))
  )
  (let (
    (result (grant-consent 
      (get provider consent-data)
      (get duration consent-data)
      (get permissions consent-data)
      (get purpose consent-data)
    ))
  )
    (match result
      success (ok (unwrap-panic (as-max-len? (append (unwrap-panic acc) success) u5)))
      error (err error)
    )
  )
)

;; Create time-limited emergency consent (patient can pre-authorize emergency access)
(define-public (create-emergency-consent
    (emergency-contact principal)
    (duration-blocks uint)
    (conditions (string-ascii 200))
  )
  (let (
    (patient (unwrap! (map-get? patients { patient-id: tx-sender }) ERR_PATIENT_NOT_FOUND))
    (consent-id (generate-consent-id))
    (capped-duration (if (<= duration-blocks MAX_CONSENT_DURATION) duration-blocks MAX_CONSENT_DURATION))
    (expires-at (+ block-height capped-duration))
  )
    ;; Create emergency consent with full permissions
    (map-set consent-forms
      { patient-id: tx-sender, provider-id: emergency-contact }
      {
        consent-id: consent-id,
        granted-at: block-height,
        expires-at: expires-at,
        permissions: u15, ;; All permissions for emergency situations
        purpose: conditions,
        is-active: true,
        revoked-at: none
      }
    )
    
    (print { 
      event: "emergency-consent-created", 
      patient: tx-sender, 
      emergency-contact: emergency-contact,
      consent-id: consent-id,
      expires-at: expires-at
    })
    (ok consent-id)
  )
)

;; ===================
;; READ-ONLY FUNCTIONS - DATA QUERIES
;; ===================

;; Get patient information
(define-read-only (get-patient-info (patient-id principal))
  (map-get? patients { patient-id: patient-id })
)

;; Get healthcare provider information
(define-read-only (get-provider-info (provider-id principal))
  (map-get? healthcare-providers { provider-id: provider-id })
)

;; Get consent information between patient and provider
(define-read-only (get-consent-info (patient-id principal) (provider-id principal))
  (map-get? consent-forms { patient-id: patient-id, provider-id: provider-id })
)

;; Get medical record information
(define-read-only (get-record-info (record-id uint))
  (map-get? medical-records { record-id: record-id })
)

;; Check if consent is currently valid
(define-read-only (check-consent-validity (patient-id principal) (provider-id principal))
  (match (map-get? consent-forms { patient-id: patient-id, provider-id: provider-id })
    consent-data (is-consent-valid consent-data)
    false
  )
)

;; Get consent expiration time
(define-read-only (get-consent-expiration (patient-id principal) (provider-id principal))
  (match (map-get? consent-forms { patient-id: patient-id, provider-id: provider-id })
    consent-data (some (get expires-at consent-data))
    none
  )
)

;; Check specific permission level for a provider
(define-read-only (has-consent-permission (patient-id principal) (provider-id principal) (required-permission uint))
  (match (map-get? consent-forms { patient-id: patient-id, provider-id: provider-id })
    consent-data (and 
      (is-consent-valid consent-data)
      (has-permission (get permissions consent-data) required-permission)
    )
    false
  )
)

;; Get total number of active consents for a patient
(define-read-only (get-patient-consent-count (patient-id principal))
  ;; This would require iteration in a full implementation
  ;; For now, return a placeholder - in practice, this would be tracked separately
  u0
)

;; Validate if provider is verified and active
(define-read-only (is-provider-verified (provider-id principal))
  (match (map-get? healthcare-providers { provider-id: provider-id })
    provider-data (get is-verified provider-data)
    false
  )
)
