# Work History Verification Smart Contract

A decentralized employment background verification system built on the Stacks blockchain using Clarity smart contracts. This system implements self-sovereign identity principles, allowing users to maintain control over their employment history while enabling trusted verification from employers.

## 🌟 Features

- **Self-Sovereign Identity**: Users own and control their employment data
- **Decentralized Verification**: Employers can verify employment records on-chain
- **Immutable Records**: All employment history and verifications are permanently stored
- **Privacy-Focused**: Users decide what information to share and with whom
- **Transparent Process**: All verification actions are auditable on the blockchain
- **Multi-Party Trust**: Supports verification from multiple employers

## 🏗️ Architecture

The contract consists of four main data structures:

1. **User Profiles**: Basic identity information and statistics
2. **Employment Records**: Detailed work history entries
3. **Employer Verifications**: Verification status and notes from employers
4. **Authorized Employers**: Registry of legitimate employers

## 📋 Prerequisites

- Stacks blockchain testnet/mainnet access
- Clarity CLI or Stacks wallet for contract interaction
- STX tokens for transaction fees

## 🚀 Getting Started

### Deploy the Contract

```bash
# Using Clarinet (recommended for development)
clarinet deploy

# Or deploy directly to testnet/mainnet
stx deploy_contract work-history-verification contract.clar
```

### Basic Usage Flow

1. **User Registration**
   ```clarity
   (contract-call? .work-history-verification create-user-profile)
   ```

2. **Employer Registration**
   ```clarity
   (contract-call? .work-history-verification register-as-employer "Company Name")
   ```

3. **Add Employment Record**
   ```clarity
   (contract-call? .work-history-verification add-employment-record 
     'SP1EMPLOYER... 
     "Tech Corp" 
     "Software Engineer" 
     u1640995200  ;; Start date (timestamp)
     (some u1672531200)  ;; End date (optional)
     "$80k-$100k")
   ```

4. **Employer Verification**
   ```clarity
   (contract-call? .work-history-verification verify-employment 
     'SP1USER... 
     u1  ;; Employment ID
     "Verified employment record - excellent performance")
   ```

## 📚 API Reference

### User Functions

#### `create-user-profile()`
Creates a new user profile for employment record management.
- **Returns**: `(response bool uint)`
- **Errors**: `ERR_ALREADY_EXISTS` if profile exists

#### `add-employment-record(employer, company-name, position, start-date, end-date, salary-range)`
Adds a new employment record to user's history.
- **Parameters**:
  - `employer`: Principal of the employer
  - `company-name`: Company name (max 100 chars)
  - `position`: Job title (max 100 chars)
  - `start-date`: Employment start date (block height or timestamp)
  - `end-date`: Employment end date (optional)
  - `salary-range`: Salary information (max 50 chars)
- **Returns**: `(response uint uint)` - Employment ID on success
- **Errors**: `ERR_NOT_FOUND`, `ERR_INVALID_DATES`

#### `update-employment-record(employment-id, company-name, position, start-date, end-date, salary-range)`
Updates an existing employment record.
- **Parameters**: Same as add-employment-record plus `employment-id`
- **Returns**: `(response bool uint)`
- **Errors**: `ERR_NOT_FOUND`, `ERR_INVALID_DATES`

### Employer Functions

#### `register-as-employer(company-name)`
Registers as an authorized employer for verification purposes.
- **Parameters**:
  - `company-name`: Official company name (max 100 chars)
- **Returns**: `(response bool uint)`
- **Errors**: `ERR_ALREADY_EXISTS`

#### `verify-employment(user, employment-id, notes)`
Verifies a user's employment record.
- **Parameters**:
  - `user`: Principal of the employee
  - `employment-id`: ID of the employment record
  - `notes`: Verification notes (max 500 chars)
- **Returns**: `(response bool uint)`
- **Errors**: `ERR_NOT_FOUND`, `ERR_UNAUTHORIZED`, `ERR_INVALID_EMPLOYER`

#### `revoke-verification(user, employment-id, notes)`
Revokes a previously issued verification.
- **Parameters**: Same as verify-employment
- **Returns**: `(response bool uint)`
- **Errors**: `ERR_NOT_FOUND`

### Query Functions

#### `get-user-profile(user)`
Retrieves user profile information.
- **Parameters**: `user` - Principal of the user
- **Returns**: Optional user profile data

#### `get-employment-record(user, employment-id)`
Gets specific employment record details.
- **Parameters**: 
  - `user` - Principal of the user
  - `employment-id` - Employment record ID
- **Returns**: Optional employment record data

#### `get-verification-status(employer, user, employment-id)`
Checks verification status for an employment record.
- **Returns**: Optional verification data

#### `is-verified-employment(user, employment-id)`
Simple boolean check for employment verification.
- **Returns**: `bool`

## 🔒 Security Features

- **Authorization Checks**: Only authorized parties can modify records
- **Data Validation**: Input validation for dates and employer relationships
- **Error Handling**: Comprehensive error codes for different failure scenarios
- **Immutable History**: All changes are tracked with timestamps

## 🎯 Use Cases

1. **Job Applications**: Candidates can provide verifiable employment history
2. **Background Checks**: Employers can quickly verify past employment
3. **Professional Networking**: Build trusted professional profiles
4. **Compliance**: Meet regulatory requirements for employment verification
5. **Freelancer Verification**: Independent contractors can build verified work histories

## 🔧 Error Codes

- `ERR_UNAUTHORIZED (100)`: Insufficient permissions
- `ERR_NOT_FOUND (101)`: Record not found
- `ERR_ALREADY_EXISTS (102)`: Record already exists
- `ERR_INVALID_DATES (103)`: Invalid date range
- `ERR_INVALID_EMPLOYER (104)`: Employer mismatch

## 🧪 Testing

```bash
# Run contract tests
clarinet test

# Check contract syntax
clarinet check

# Interactive testing
clarinet console
```

## 📖 Example Scenarios

### Scenario 1: New Graduate
```clarity
;; 1. Create profile
(contract-call? .work-history-verification create-user-profile)

;; 2. Add internship record
(contract-call? .work-history-verification add-employment-record 
  'SP1COMPANY... "StartupXYZ" "Software Intern" u1640000000 (some u1645000000) "Unpaid")
```

### Scenario 2: Job Verification
```clarity
;; Employer verifies the employment
(contract-call? .work-history-verification verify-employment 
  'SP1GRADUATE... u1 "Completed successful 6-month internship")
```

### Scenario 3: Background Check
```clarity
;; Check if employment is verified
(contract-call? .work-history-verification is-verified-employment 'SP1GRADUATE... u1)
;; Returns: true

;; Get full verification details
(contract-call? .work-history-verification get-verification-status 
  'SP1COMPANY... 'SP1GRADUATE... u1)
```

**Built with ❤️ on Stacks blockchain**