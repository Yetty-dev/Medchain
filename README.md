# MedChain: Healthcare Consent & Medical Records on Blockchain

![Stacks](https://img.shields.io/badge/Blockchain-Stacks-purple)
![Clarity](https://img.shields.io/badge/Language-Clarity-blue)
![HIPAA](https://img.shields.io/badge/Compliance-HIPAA-green)
![License](https://img.shields.io/badge/License-MIT-orange)

> **A comprehensive, HIPAA-compliant smart contract for managing patient consent forms and medical record access permissions on the Stacks blockchain.**

MedChain revolutionizes healthcare data management by providing secure, transparent, and auditable consent management while maintaining patient privacy and control through blockchain technology.

---

## 🏥 Overview

MedChain addresses critical challenges in healthcare data management:

- **Patient Privacy**: Patients maintain complete control over their medical data
- **Provider Access**: Streamlined, consent-based access for healthcare providers  
- **Audit Compliance**: Immutable audit trails for HIPAA and regulatory compliance
- **Emergency Access**: Secure protocols for critical medical situations
- **Data Integrity**: Cryptographic verification of medical record authenticity

## ✨ Key Features

### 🔐 Core Infrastructure
- **Granular Permissions**: Multi-level access control (Read, Write, Delete, Admin)
- **Time-Bounded Consent**: Configurable expiration with automatic enforcement
- **Comprehensive Error Handling**: 9 distinct error codes for robust operation
- **Event-Driven Architecture**: Complete audit trail with blockchain timestamps
- **Security-First Design**: Built-in protection against common vulnerabilities

### 👤 Patient & Provider Management
- **Patient Registration**: Complete medical identity management with emergency contacts
- **Provider Verification**: Licensed healthcare provider credential validation
- **Active Status Tracking**: Account management with compliance-driven controls
- **Medical Record Numbers**: Integration with existing healthcare identification systems

### 📋 Advanced Consent Management
- **Flexible Consent Granting**: Purpose-specific permissions with custom durations
- **Instant Consent Revocation**: Immediate withdrawal with permanent audit trail
- **Consent Updates**: Modify permissions and extend durations without re-authorization
- **Batch Operations**: Efficiently manage multiple provider relationships
- **Emergency Pre-Authorization**: Patient-controlled emergency access setup

### 🏥 Medical Record Management
- **Hash-Based Integrity**: Cryptographic verification of medical record authenticity
- **Access Level Classification**: Sensitive data protection with granular controls
- **Provider-Only Creation**: Medical records created only by verified healthcare providers
- **Comprehensive Metadata**: Complete record lifecycle tracking

### 🛡️ Administrative & Emergency Controls
- **Provider Verification**: Admin-controlled healthcare provider credentialing
- **Emergency Override**: Critical situation access with detailed audit logging
- **Compliance Management**: Patient account deactivation for regulatory requirements
- **System Oversight**: Global administrative controls and monitoring

### 📊 Analytics & Audit System
- **Real-Time Statistics**: Provider activity, patient engagement, and system metrics
- **Comprehensive Audit Trails**: Complete access logging with purpose tracking
- **Compliance Reporting**: Time-range filtered audit reports for regulatory compliance
- **Activity Analytics**: Detailed insights into system usage and performance

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet) - Stacks smart contract development toolkit
- [Stacks CLI](https://docs.stacks.co/build/command-line-interface) - For blockchain interactions
- [Node.js](https://nodejs.org/) (v14+) - For running tests

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Yetty-dev/Medchain.git
   cd medchain
   ```

2. **Install Dependencies**
   ```bash
   # Install Clarinet (macOS)
   brew install clarinet
   
   # Or download from releases
   curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz -o clarinet.tar.gz
   ```

3. **Verify Installation**
   ```bash
   clarinet --version
   ```

### Quick Start

1. **Check Contract Syntax**
   ```bash
   clarinet check
   ```

2. **Run Tests**
   ```bash
   clarinet test
   ```

3. **Start Local Development Environment**
   ```bash
   clarinet integrate
   ```

4. **Deploy to Testnet**
   ```bash
   clarinet deploy --network testnet
   ```

## 📚 Usage Examples

### Patient Registration
```clarity
;; Register a new patient
(contract-call? .medchain register-patient 
  "John Doe" 
  u19800115  ;; Birth date (timestamp)
  "Emergency Contact: Jane Doe (555) 123-4567"
  "MRN-12345"
)
```

### Healthcare Provider Registration
```clarity
;; Register as healthcare provider
(contract-call? .medchain register-provider
  "Dr. Sarah Johnson"
  "MD-12345-CA"
  "Cardiology"
  "City General Hospital"
)
```

### Grant Medical Consent
```clarity
;; Patient grants consent to provider
(contract-call? .medchain grant-consent
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; Provider principal
  u8760     ;; Duration: ~6 months in blocks
  u3        ;; Permissions: Read + Write
  "Annual physical examination and follow-up care"
)
```

### Create Medical Record
```clarity
;; Provider creates medical record (requires consent)
(contract-call? .medchain create-medical-record
  'PATIENT_PRINCIPAL
  "Lab Results"
  0x1234567890abcdef...  ;; Record hash
  u2        ;; Access level
  true      ;; Is sensitive
)
```

### Access Medical Record
```clarity
;; Provider accesses medical record with purpose
(contract-call? .medchain access-medical-record-enhanced
  u123      ;; Record ID
  "Review for upcoming surgery consultation"
)
```

## 🏗️ Architecture

### Smart Contract Structure

```
MedChain Contract (877 lines)
├── Constants & Error Codes
├── Data Structures
│   ├── Patients Map
│   ├── Healthcare Providers Map
│   ├── Consent Forms Map
│   ├── Medical Records Map
│   └── Analytics Maps
├── Private Functions
│   ├── ID Generation
│   ├── Permission Validation
│   └── Statistics Updates
├── Public Functions
│   ├── Registration (Patient/Provider)
│   ├── Consent Management
│   ├── Medical Records
│   ├── Administrative Controls
│   └── Emergency Access
└── Read-Only Functions
    ├── Data Queries
    ├── Analytics
    └── System Information
```

### Permission Levels
- **PERMISSION_READ (1)**: View medical records
- **PERMISSION_WRITE (2)**: Create new medical records
- **PERMISSION_DELETE (4)**: Remove existing records  
- **PERMISSION_ADMIN (8)**: Administrative access

### Data Flow
1. **Patient Registration** → **Provider Verification** → **Consent Grant**
2. **Medical Record Creation** → **Access Validation** → **Audit Logging**
3. **Analytics Collection** → **Compliance Reporting** → **System Monitoring**

## 🧪 Testing

### Run Test Suite
```bash
# Run all tests
clarinet test

# Run specific test
clarinet test tests/medchain_test.ts

# Check contract syntax
clarinet check

# Run in console mode for debugging
clarinet console
```

### Test Coverage
- Patient and provider registration
- Consent management operations
- Medical record creation and access
- Administrative functions
- Emergency access protocols
- Analytics and audit functions

## 📈 Analytics & Monitoring

### Key Metrics Tracked
- **Total Patients**: Number of registered patients
- **Total Providers**: Number of verified healthcare providers
- **Active Consents**: Current valid consent relationships
- **Medical Records**: Total records in the system
- **Access Events**: Complete audit trail of all access attempts

### Audit Capabilities
- **Time-Range Reports**: Generate compliance reports for specific periods
- **Provider Activity**: Track healthcare provider system usage
- **Patient Engagement**: Monitor patient consent and record activity
- **Emergency Access**: Detailed logging of critical situation protocols

## 🔒 Security Features

### Built-in Protections
- **Reentrancy Prevention**: Clarity language-level protection
- **Integer Overflow Protection**: Automatic transaction abortion on overflow
- **Input Validation**: Comprehensive parameter validation
- **Access Control**: Multi-layered permission verification
- **Audit Trails**: Immutable record of all system interactions

### HIPAA Compliance
- **Patient Consent Management**: Complete control over medical data access
- **Access Purpose Tracking**: Detailed logging of why records were accessed
- **Time-Bounded Permissions**: Automatic expiration of access rights
- **Emergency Access Protocols**: Secure critical situation handling
- **Comprehensive Audit Trails**: Complete system activity logging

## 🤝 Contributing

We welcome contributions to MedChain! Please follow these steps:

1. **Fork the Repository**
2. **Create Feature Branch** (`git checkout -b feature/amazing-feature`)
3. **Commit Changes** (`git commit -m 'Add amazing feature'`)
4. **Push to Branch** (`git push origin feature/amazing-feature`)
5. **Open Pull Request**

### Development Guidelines
- Follow Clarity coding standards
- Add comprehensive tests for new features
- Update documentation as needed
- Ensure HIPAA compliance for healthcare-related features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Stacks Foundation** - For the secure and scalable blockchain platform
- **Clarity Language** - For the predictable and secure smart contract environment
- **Healthcare Community** - For inspiring the need for better healthcare data management
- **Open Source Contributors** - For the tools and libraries that made this possible

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/Yetty-dev/Medchain/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Yetty-dev/Medchain/discussions)
- **Email**: [Insert contact email]
- **Documentation**: [Link to full documentation]

---

## 🌟 Why MedChain?

> "Healthcare data is among the most sensitive and critical information in our lives. MedChain ensures that patients maintain control while enabling healthcare providers to deliver the best care possible through secure, transparent, and auditable data management."

**Built with ❤️ for the healthcare community**

---

### Quick Links
- [🏥 Healthcare Use Cases](docs/use-cases.md)
- [🔧 API Documentation](docs/api.md)
- [🛡️ Security Guide](docs/security.md)
- [📊 Analytics Guide](docs/analytics.md)
- [🚀 Deployment Guide](docs/deployment.md)
